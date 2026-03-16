from abc import abstractmethod
import subprocess


class FlatpakApiContract:

    @abstractmethod
    def get_installed_app_id_list(self) -> list[str]:
        pass

    @abstractmethod
    def get_number_of_updates(self) -> int:
        pass

    @abstractmethod
    def get_info_by_id(self, app_id: str) -> subprocess.CompletedProcess[bytes]:
        pass

    @abstractmethod
    def is_app_id_installed(self, app_id: str) -> bool:
        pass

    @abstractmethod
    def uninstall_by_id(self, app_id: str):
        pass

    @abstractmethod
    def get_install_call(self, app_id: str, flags) -> list:
        pass

    @abstractmethod
    def get_override_filesystem_call(self, app_id: str, filesystem: str) -> list:
        pass
