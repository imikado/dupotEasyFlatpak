import json

from domain.conf.path_conf import PathConf
from domain.contract.system_api_contract import SystemApiContract


class ApplicationVersionEntity:

    FIELD_VERSION = "version"

    _installed_version: str = "0.0.0"
    _current_version: str = "X.X.X"

    _instance: "ApplicationVersionEntity | None" = None

    def __new__(cls, *_args, **_kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def load(self, system_api: SystemApiContract):

        path_conf = PathConf()

        # current
        current_version_path = path_conf.get_asset_application_version_path()
        if not system_api.file_exists(current_version_path):
            raise ValueError(
                f"Error when try to identify current application version (in asset {current_version_path})"
            )

        current_content = system_api.read_file(current_version_path)
        current_version_object = json.loads(current_content)

        if self.FIELD_VERSION in current_version_object:
            self._current_version = current_version_object[self.FIELD_VERSION]
        else:
            raise ValueError(
                "Missing field " + self.FIELD_VERSION + " in " + current_version_path
            )

        # installed
        installed_version_path = path_conf.get_installed_version_path()
        if not system_api.file_exists(installed_version_path):
            print(f"installed version is missing {installed_version_path}")
            return

        content = system_api.read_file(installed_version_path)
        version_object = json.loads(content)

        if self.FIELD_VERSION in version_object:
            self._installed_version = version_object[self.FIELD_VERSION]
        else:
            raise ValueError(
                "Missing field " + self.FIELD_VERSION + " in " + installed_version_path
            )

        pass

    def get_version(self) -> str:
        return self._installed_version

    def get_current_version(self) -> str:
        return self._current_version

    def is_current_version(self) -> bool:
        return self._installed_version == self._current_version
