import os


class PathConf:
    _instance = None

    ID_PATH = "org.dupot.easyflatpak"

    ID_DB_PATH = "db"
    ID_JSON_PATH = "json"
    ID_ARCHIVE_PATH = "archive"
    ID_RECIPES_PATH = "recipes"

    INSTALLED_VERSION_FILENAME = "installed_version.json"
    DATABASE_FILENAME = "flathub_database.db"
    ICON_PATH = "icons"
    ICON_ARCHIVE = "icons.zip"

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def get_asset_path(self) -> str:
        return self.get_path_list_join(
            [os.path.dirname(__file__), "..", "..", "assets"]
        )

    def get_path_list_join(self, path_list: list):
        return "/".join(path_list)

    # assets
    def get_asset_database_path(self) -> str:
        return self.get_path_list_join(
            [self.get_asset_path(), self.ID_DB_PATH, self.DATABASE_FILENAME]
        )

    def get_asset_application_version_path(self) -> str:
        return self.get_path_list_join(
            [self.get_asset_path(), self.ID_JSON_PATH, self.INSTALLED_VERSION_FILENAME]
        )

    def get_asset_icons_archive_path(self) -> str:
        return self.get_path_list_join(
            [self.get_asset_path(), self.ID_ARCHIVE_PATH, self.ICON_ARCHIVE]
        )

    def get_asset_recipes_path(self) -> str:
        return self.get_path_list_join([self.get_asset_path(), self.ID_RECIPES_PATH])

    # user
    def set_data_path(self, data_path):
        self._data_path = data_path

    def get_data_path(self) -> str:
        return self.get_path_list_join([self._data_path, self.ID_PATH])

    def get_database_path(self) -> str:
        return self.get_path_list_join([self.get_data_path(), self.DATABASE_FILENAME])

    def get_installed_version_path(self) -> str:
        return self.get_path_list_join(
            [self.get_data_path(), self.INSTALLED_VERSION_FILENAME]
        )

    def get_icons_path(self) -> str:
        return self.get_path_list_join([self.get_data_path(), self.ICON_PATH])

    def get_icons_archive_path(self) -> str:
        return self.get_path_list_join([self.get_data_path(), self.ICON_ARCHIVE])
