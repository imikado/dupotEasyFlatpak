from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.contract.flatpakrepo_repository_contract import FlatpakRepoRepositoryContract


class DeleteRemoteRepoUc:

    _flatpak_api: FlatpakApiContract
    _flatpakrepo_repository: FlatpakRepoRepositoryContract
    _appstream_repository: AppstreamRepositoryContract

    def __init__(
        self,
        flatpak_api: FlatpakApiContract,
        flatpakrepo_repository: FlatpakRepoRepositoryContract,
        appstream_repository: AppstreamRepositoryContract,
    ):
        self._flatpak_api = flatpak_api
        self._flatpakrepo_repository = flatpakrepo_repository
        self._appstream_repository = appstream_repository

    def delete(self, id: str) -> tuple[bool, str]:
        if id == "flathub":
            return False, "The Flathub repository cannot be removed"

        entity = self._flatpakrepo_repository.get_by_id(id)
        if not entity:
            return False, "Repository not found"

        scope = self._flatpakrepo_repository.get_scope_flag(id, "--user")

        success, error_message = self._flatpak_api.remove_remote(id, scope)
        if not success and self._flatpak_api.remote_exists(id, scope):
            # Still registered in flatpak and the removal genuinely failed
            # (e.g. permission issue) — surface it instead of silently
            # dropping our tracking row while the remote stays behind.
            return False, error_message

        # Either removed, or already gone/unreachable (removed outside the
        # app, broken remote, network down…) — nothing left to clean up on
        # the flatpak side, so just stop tracking it.
        self._flatpakrepo_repository.delete(id)
        self._appstream_repository.delete_by_flatpak_repo_id(id)
        return True, ""
