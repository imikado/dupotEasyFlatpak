from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.contract.flatpakrepo_repository_contract import FlatpakRepoRepositoryContract


class EditRemoteRepoUc:

    _flatpak_api: FlatpakApiContract
    _flatpakrepo_repository: FlatpakRepoRepositoryContract

    def __init__(self, flatpak_api: FlatpakApiContract, flatpakrepo_repository: FlatpakRepoRepositoryContract):
        self._flatpak_api = flatpak_api
        self._flatpakrepo_repository = flatpakrepo_repository

    def edit(self, id: str, url: str) -> tuple[bool, str]:
        entity = self._flatpakrepo_repository.get_by_id(id)
        if not entity:
            return False, "Repository not found"

        scope = self._flatpakrepo_repository.get_scope_flag(id, "--user")

        old_url = entity.getUrl()

        success, error_message = self._flatpak_api.modify_remote(id, url, scope)
        if not success:
            return False, error_message

        verified, verify_error_message = self._flatpak_api.verify_remote(id, scope)
        if not verified:
            # Roll back to the previous, known-working URL.
            self._flatpak_api.modify_remote(id, old_url, scope)
            return False, verify_error_message or "This repository is not reachable or invalid"

        self._flatpakrepo_repository.insert_repo_id(id, url, entity.getApi(), entity.getScope())
        return True, ""
