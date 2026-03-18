#!/usr/bin/env python3

from domain.UseCase.update_database_from_api_uc import UpdateDatabaseFromApiUc
from domain.conf.path_conf import PathConf
from domain.entity.application_version_entity import ApplicationVersionEntity
from domain.entity.user_settings_entity import UserSettingsEntity
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.system_api import SystemApi
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
    localedir = "./infrastructure/locales"

    # Set up Gettext
    en_i18n = gettext.translation(
        appname, localedir, fallback=True, languages=["en", "fr"]
    )

    # Create the "magic" function
    en_i18n.install()

    system_api = SystemApi()

    path_conf = PathConf()
    path_conf.set_data_path(GLib.get_user_data_dir())

    data_path = path_conf.get_data_path()
    print(f"data path is {data_path}")

    should_copy_default_user_settings = False

    user_settings_current_path = path_conf.get_asset_usersettings_path
    if system_api.file_exists(user_settings_current_path):
        should_copy_default_user_settings = True
    else:
        application_user_settings = UserSettingsEntity()

        current_user_settings = UserSettingsEntity(
            system_api.read_json_file_obj(user_settings_current_path)
        )

        if application_user_settings.version != current_user_settings.version:
            should_copy_default_user_settings = True

    if should_copy_default_user_settings:
        system_api.write_file(
            path_conf.get_user_settings_path(),
            application_user_settings.get_json_string(),
        )

    application_version_entity = ApplicationVersionEntity(system_api)
    if not application_version_entity.is_current_version():

        print("not current version, will install v2026-03-16 22:38")

        if not system_api.file_exists(data_path):
            system_api.create_dir(data_path)

        icons_archive_path = path_conf.get_icons_archive_path()
        if system_api.file_exists(icons_archive_path):
            system_api.remove_file(icons_archive_path)

        file_path_to_copy_list = [
            PathToCopy(
                path_conf.get_asset_database_path(),
                path_conf.get_database_path(),
            ),
            PathToCopy(
                path_conf.get_asset_application_version_path(),
                path_conf.get_installed_version_path(),
            ),
            PathToCopy(
                path_conf.get_asset_icons_archive_path(),
                icons_archive_path,
            ),
        ]

        for path_to_copy_loop in file_path_to_copy_list:
            system_api.copy_file(path_to_copy_loop.path_from, path_to_copy_loop.path_to)

        icons_directory_path = path_conf.get_icons_path()
        if system_api.file_exists(icons_directory_path):
            system_api.remove_directory(icons_directory_path)

        system_api.unzip_archive_to(icons_archive_path, path_conf.get_data_path())

        update_database_from_api = UpdateDatabaseFromApiUc(
            FlathubApi(), AppstreamRepository(), SystemApi()
        )
        update_database_from_api.process()

    app = AppWindow()
    app.run(None)


if __name__ == "__main__":
    main()
