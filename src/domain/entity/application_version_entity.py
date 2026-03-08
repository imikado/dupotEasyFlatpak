import json

from domain.contract.system_api_contract import SystemApiContract


class ApplicationVersionEntity:

    CURRENT_VERSION = "1.0.0"

    FIELD_VERSION = "version"

    _version: str = "0.0.0"

    def __init__(self, system_api: SystemApiContract, path_to_load: str):
        if not system_api.file_exists(path_to_load):
            return

        content = system_api.read_file(path_to_load)
        version_object = json.loads(content)

        if self.FIELD_VERSION in version_object:
            self._version = version_object[self.FIELD_VERSION]
        else:
            raise ValueError(
                "Missing field " + self.FIELD_VERSION + " in " + path_to_load
            )

        pass

    def get_version(self) -> str:
        return self._version

    def is_current_version(self) -> bool:
        return self._version == self.CURRENT_VERSION
