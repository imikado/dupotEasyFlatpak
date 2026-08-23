from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flatpak_api_contract import FlatpakApiContract
from infrastructure.repository.local_apps_repository import LocalAppsRepository


class SyncLocalInstalledAppsUc:

    _flatpak_api: FlatpakApiContract
    _appstream_repository: AppstreamRepositoryContract
    _local_apps_repository: LocalAppsRepository

    def __init__(
        self,
        flatpak_api: FlatpakApiContract,
        appstream_repository: AppstreamRepositoryContract,
        local_apps_repository: LocalAppsRepository,
    ):
        self._flatpak_api = flatpak_api
        self._appstream_repository = appstream_repository
        self._local_apps_repository = local_apps_repository

    def process(self):
        for installed_app_loop in self._flatpak_api.get_installed_app_list():
            app_id = installed_app_loop.getId()

            # Already known through the Flathub appstream DB — nothing to track.
            if self._appstream_repository.get_by_id(app_id):
                continue

            # Already tracked as a local-only app (previous install/import).
            if self._local_apps_repository.get_by_id(app_id):
                continue

            self._local_apps_repository.insert_or_update(
                app_id,
                installed_app_loop.getName(),
                "",
                installed_app_loop.getVersion(),
            )
