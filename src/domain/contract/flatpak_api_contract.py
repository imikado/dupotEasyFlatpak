from abc import abstractmethod
import subprocess

from domain.entity.flatpak_history_entity import FlatpakHistoryEntity
from domain.entity.installed_version_entity import InstalledVersionEntity
from domain.entity.update_available_entity import UpdateAvailableEntity


class FlatpakApiContract:

    @abstractmethod
    def get_installed_app_id_list(self) -> list[str]:
        pass

    @abstractmethod
    def get_installed_list(self) -> list[InstalledVersionEntity]:
        pass

    @abstractmethod
    def get_number_of_updates(self) -> int:
        pass

    @abstractmethod
    def get_available_update_list(self) -> list[UpdateAvailableEntity]:
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

    @abstractmethod
    def get_override_filesystems(self, app_id: str) -> list[str]:
        pass

    @abstractmethod
    def run_by_id(self, app_id: str):
        pass

    @abstractmethod
    def get_installed_commit_by_id(self, app_id: str) -> str | None:
        pass

    @abstractmethod
    def get_history_list_by_id(self, app_id: str) -> list[FlatpakHistoryEntity]:
        pass

    @abstractmethod
    def get_installation_scope(self, app_id: str) -> str:
        pass

    @abstractmethod
    def get_downgrade_call(self, app_id: str, commit: str, *flags) -> list:
        pass

    @abstractmethod
    def update_version_by_id_and_commit(
        self, app_id: str, commit: str
    ) -> subprocess.CompletedProcess:
        pass

    @abstractmethod
    def get_update_call(self, app_id: str) -> list:
        pass
