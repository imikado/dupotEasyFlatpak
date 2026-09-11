#!/usr/bin/env python3

import os
import shutil
import sys

from domain.UseCase.add_new_remote_repo_uc import AddNewRemoteRepoUc
from domain.UseCase.get_home_content_uc import GetHomeContentUC
from domain.UseCase.sync_local_installed_apps_uc import SyncLocalInstalledAppsUc
from domain.UseCase.update_database_from_api_uc import UpdateDatabaseFromApiUc
from domain.conf.path_conf import PathConf
from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.entity.application_version_entity import ApplicationVersionEntity
from domain.entity.user_settings_entity import UserSettingsEntity
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.api.oci_api import OciApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.repository.flatpakrepo_repository import FlatpakRepoRepository
from infrastructure.repository.local_apps_repository import LocalAppsRepository
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

    # On some fresh installs the desktop session hasn't exported LANG/LC_ALL
    # into the sandbox yet at this point, so GLib.get_language_names() comes
    # back empty/"C" even though the system is set to e.g. French. Fall back
    # to reading the raw locale env vars directly in that case.
    env_languages = [
        v
        for v in ":".join(
            os.environ.get(name, "")
            for name in ("LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG")
        ).split(":")
        if v and v != "C"
    ]

    # Resolve the real system locale into a Flathub API locale code, for use
    # whenever the user's language setting is "System".
    supported_codes = {"ar", "de", "es", "fr", "it", "ro"}  # pt handled separately (-> pt_BR)
    system_language_code = UserSettingsEntity.LANGUAGE_EN_CODE
    for language_name in languages + env_languages:
        base = language_name.split(".")[0].split("_")[0].lower()
        if base == "pt":
            system_language_code = "pt_BR"
            break
        if base in supported_codes:
            system_language_code = base
            break

    print(f"GLib languages: {languages}")
    print(f"env_languages fallback: {env_languages}")
    print('system_language_code:'+system_language_code)

    UserSettingsEntity().set_system_language_code(system_language_code)

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

        # Older Nix packages copied these files from /nix/store with their
        # 0444 mode. Repair them before the first SQLite/version write. Icon
        # trees are repaired lazily by copy_dir() when an upgrade copies them.
        system_api.make_tree_writable(path_conf.get_database_path())
        system_api.make_tree_writable(path_conf.get_installed_version_path())

        # On a fresh install the user data dir has no database yet. Several
        # repositories below (ApiCacheRepository, ...) open it unconditionally
        # via DatabaseApi, and sqlite3.connect() silently creates an empty
        # file if none exists — leaving a DB with no tables at all and every
        # query failing with "no such table". Make sure the shipped DB is in
        # place before anything can touch it, independent of the
        # is_current_version() reinstall logic further below (which only
        # runs on install/update, not on every launch).
        if not system_api.file_exists(data_path):
            system_api.create_dir(data_path)
        if not system_api.file_exists(path_conf.get_database_path()):
            system_api.copy_file(
                path_conf.get_asset_database_path(),
                path_conf.get_database_path(),
            )

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
        # Must be read before the install/update block below, since that
        # block is what creates installed_version_path in the first place —
        # by the time it's run, the file always exists and this would read
        # back as False even on a genuinely fresh install.
        is_first_install = not system_api.file_exists(
            path_conf.get_installed_version_path()
        )
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

            AddNewRemoteRepoUc(FlatpakApi(),FlatpakRepoRepository()).sync()

            if is_first_install:
                print("first install, syncing already-installed flatpak apps")
                SyncLocalInstalledAppsUc(
                    FlatpakApi(), AppstreamRepository(), LocalAppsRepository()
                ).process()

            #shutil .copytree(path_conf.get_asset_icons_archive_path(), path_conf.get_icons_path(), dirs_exist_ok=True)

        # GetHomeContentUC.load() (constructor) refreshes the cached home
        # id-lists (trending/popular/apps-of-the-week/...) whenever its own
        # cache is stale — which it always is on a fresh install, since the
        # timestamp baked into the shipped DB is from packaging time. Must
        # run BEFORE UpdateDatabaseFromApiUc so the translation pass below
        # covers the id list that will actually be shown, not the stale
        # shipped one it would otherwise replace right after.
        GetHomeContentUC(ApiCacheRepository(), AppstreamRepository(), FlathubApi(), SystemApi())

        UpdateDatabaseFromApiUc(
            FlathubApi(),
            AppstreamRepository(),
            SystemApi(),
            ApiCacheRepository(),
            FlatpakRepoRepository(),
            FlatpakApi(),
            lang_code,
            OciApi(),
        ).process()

    app = AppWindow(init_fn=init_fn)
    app.run(sys.argv)


if __name__ == "__main__":
    main()
