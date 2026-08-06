#!/usr/bin/env python3

import os
import shutil
import sys

from domain.UseCase.update_database_from_api_uc import UpdateDatabaseFromApiUc
from domain.conf.path_conf import PathConf
from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.entity.application_version_entity import ApplicationVersionEntity
from domain.entity.user_settings_entity import UserSettingsEntity
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.app_window import AppWindow
from gi.repository import GLib

import gettext


class PathToCopy:

    def __init__(self, path_from: str, path_to: str):
        self.path_from = path_from
        self.path_to = path_to
        pass


def main():
    # Set the local directory
    appname = "Easy_flatpak"
    localedir = os.path.join(os.path.dirname(__file__), "infrastructure", "locales")

    # GLib.get_language_names() is the reliable source for locale in GTK/Flatpak apps
    # e.g. ['fr_FR.UTF-8', 'fr_FR', 'fr', 'C'] — gettext handles the variants automatically
    languages = [l for l in GLib.get_language_names() if l != "C"]
    en_i18n = gettext.translation(
        appname,
        localedir,
        languages=languages,
        fallback=True,
    )

    # Create the "magic" function
    en_i18n.install()


    def init_fn():
        system_api = SystemApi()
        should_reset_lastupdate=False

        # On some installations, fontconfig falls back to a font without
        # proper Arabic shaping (joined letter forms), causing Arabic text
        # to render as disconnected glyphs. Refresh the font cache to fix it.
        if any(l.startswith("ar") for l in languages):
            flatpak_api = FlatpakApi()
            if flatpak_api.is_arabic_font_shaping_broken():
                print("Arabic font shaping looks broken, refreshing font cache")
                flatpak_api.clean_cache()

        path_conf = PathConf()
        path_conf.set_data_path(GLib.get_user_data_dir())
        os.makedirs(path_conf.get_data_path(), exist_ok=True)

        data_path = path_conf.get_data_path()
        print(f"data path is {data_path}")

        current_user_settings = UserSettingsEntity()

        should_copy_default_user_settings = False

        user_settings_current_path = path_conf.get_user_settings_path()
        if not system_api.file_exists(user_settings_current_path):
            print(f"user setting is missing : {user_settings_current_path}")
            should_copy_default_user_settings = True
        else:
            current_user_settings.load(
                system_api.read_json_file_obj(user_settings_current_path)
            )

            if UserSettingsEntity.DEFAULT_VERSION != current_user_settings.version:
                print(
                    f"user settings is already there, but version is different current:{current_user_settings.version} vs application {UserSettingsEntity.DEFAULT_VERSION}"
                )
                current_user_settings.reset_to_defaults()
                should_copy_default_user_settings = True

        if should_copy_default_user_settings:
            print(f"install default user settings conf")
            system_api.write_file(
                user_settings_current_path,
                current_user_settings.get_json_string(),
            )

        lang_code = current_user_settings.get_language_code()

        if current_user_settings.should_force_language():
            forced_i18n = gettext.translation(
                appname,
                localedir,
                languages=[lang_code],
                fallback=True,
            )
            forced_i18n.install()

            if lang_code != UserSettingsEntity.LANGUAGE_EN_CODE:
                should_reset_lastupdate = True
        elif not any(l.startswith(UserSettingsEntity.LANGUAGE_EN_CODE) for l in languages):
            should_reset_lastupdate = True

        if not should_reset_lastupdate:
            api_cache_parameter_entity = ApiCacheRepository().get_by_id(ApiCacheRepositoryContract.ID_PARAMETERS)
            if(api_cache_parameter_entity.get_api_last_lang()!=lang_code):
                should_reset_lastupdate=True

        application_version_entity = ApplicationVersionEntity()
        application_version_entity.load(system_api)
        if not application_version_entity.is_current_version():

            print("not current version, will install")

            flatpak_api = FlatpakApi()

            flatpak_api.ensure_flathub_remote()
            flatpak_api.clean_cache()

            if not system_api.file_exists(data_path):
                system_api.create_dir(data_path)


            file_path_to_copy_list = [
                PathToCopy(
                    path_conf.get_asset_database_path(),
                    path_conf.get_database_path(),
                ),
                PathToCopy(
                    path_conf.get_asset_application_version_path(),
                    path_conf.get_installed_version_path(),
                ),
               
                
            ]

            system_api.copy_dir(path_conf.get_asset_icons_path(),data_path)

            for path_to_copy_loop in file_path_to_copy_list:
                system_api.copy_file(
                    path_to_copy_loop.path_from, path_to_copy_loop.path_to
                )

            if should_reset_lastupdate:
                AppstreamRepository().reset_updated_for_all()
                ApiCacheRepository().reset_api_lastupdate()

            #shutil .copytree(path_conf.get_asset_icons_archive_path(), path_conf.get_icons_path(), dirs_exist_ok=True)

        UpdateDatabaseFromApiUc(
            FlathubApi(), AppstreamRepository(), SystemApi(), ApiCacheRepository(),lang_code
        ).process()

    app = AppWindow(init_fn=init_fn)
    app.run(sys.argv)


if __name__ == "__main__":
    main()
