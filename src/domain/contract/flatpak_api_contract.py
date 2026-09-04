from abc import abstractmethod
import subprocess

from domain.entity.flatpak_history_entity import FlatpakHistoryEntity
from domain.entity.flatpakrepo_entity import FlatpakRepoEntity
from domain.entity.installed_version_entity import InstalledVersionEntity
from domain.entity.remote_flatpak_app_entity import RemoteFlatpakAppEntity
from domain.entity.update_available_entity import UpdateAvailableEntity


class FlatpakApiContract:

    @abstractmethod
    def get_installed_app_id_list(self) -> list[str]:
        pass

    @abstractmethod
    def get_installed_list(self) -> list[InstalledVersionEntity]:
        pass

    @abstractmethod
    def get_installed_app_list(self) -> list[RemoteFlatpakAppEntity]:
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
    def get_install_call(self, app_id: str, repo_id: str = "flathub", *flags) -> list:
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
    def ensure_flathub_remote(self):
        pass

    @abstractmethod
    def get_remote_add_call(self, id: str, url: str, scope: str = "--user") -> list:
        pass

    @abstractmethod
    def get_remote_app_list(self, flatpakRepoId: str) -> list[RemoteFlatpakAppEntity]:
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

    @abstractmethod
    def get_update_all_user_scope_call(self) -> list:
        pass

    @abstractmethod
    def get_update_all_system_scope_call(self) -> list:
        pass

    @abstractmethod
    def get_flatpak_bundle_info(self, file_path: str) -> dict:
        pass

    @abstractmethod
    def get_install_bundle_call(self, file_path: str, *flags) -> list:
        pass

    @abstractmethod
    def clean_cache(self):
        pass

    @abstractmethod
    def get_remote_repo_list(self) -> list[FlatpakRepoEntity]:
        pass

    @abstractmethod
    def add_remote(self,id:str,url:str,scope:str="--user")-> tuple[bool, str]:
        pass

    @abstractmethod
    def verify_remote(self, id: str, scope: str = "--user") -> tuple[bool, str]:
        pass

    @abstractmethod
    def remote_exists(self, id: str, scope: str = "--user") -> bool:
        pass

    @abstractmethod
    def get_remote_delete_call(self, id: str, scope: str = "--user") -> list:
        pass

    @abstractmethod
    def remove_remote(self, id: str, scope: str = "--user") -> tuple[bool, str]:
        pass

    @abstractmethod
    def get_remote_modify_call(self, id: str, url: str, scope: str = "--user") -> list:
        pass

    @abstractmethod
    def modify_remote(self, id: str, url: str, scope: str = "--user") -> tuple[bool, str]:
        pass