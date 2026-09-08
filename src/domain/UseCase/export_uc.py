from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.contract.recipe_repository_contract import RecipeRepositoryContract
from domain.contract.system_api_contract import SystemApiContract
from domain.entity.export_entity import ExportEntity
from infrastructure.repository.local_apps_repository import LocalAppsRepository


class ExportUc:

    _system_api: SystemApiContract
    _flatpak_api: FlatpakApiContract
    _recipe_repository = RecipeRepositoryContract
    _appstream_repository = AppstreamRepositoryContract

    def __init__(
        self,
        system_api: SystemApiContract,
        flatpak_api: FlatpakApiContract,
        recipe_repository: RecipeRepositoryContract,
        appstream_repository: AppstreamRepositoryContract,
    ):
        self._system_api = system_api
        self._flatpak_api = flatpak_api
        self._recipe_repository = recipe_repository
        self._appstream_repository = appstream_repository

    def export(self, path: str):
        app_ids = self._flatpak_api.get_installed_app_id_list()

        # Apps with no repo tracked in our DB (installed from a local
        # .flatpak file or a GitHub release) can't be reinstalled with a
        # plain "flatpak install <repo> <app_id>" — importing them as-is
        # would just fail. Tell them apart from normally-tracked apps so
        # each can be exported the right way (or skipped).
        known_ids = {
            a.id.lower() for a in self._appstream_repository.get_list_by_id_list(app_ids)
        }
        local_apps_by_id = {
            local_app.id.lower(): local_app
            for local_app in LocalAppsRepository().get_list()
        }

        export_data_list = []
        for app_id in app_ids:

            source_url = ""
            if app_id.lower() not in known_ids:
                local_app = local_apps_by_id.get(app_id.lower())
                if local_app and local_app.url:
                    # Installed from a GitHub release — export its source
                    # so the import step can reinstall it from there.
                    source_url = local_app.url
                else:
                    # No repo of ours, and no known source either (e.g. a
                    # random local .flatpak file) — nothing to reinstall
                    # from, so there's nothing useful to export.
                    continue

            installation_scope = self._flatpak_api.get_installation_scope(app_id)

            export_loop = ExportEntity(app_id, installation_scope, source_url)

            filesystem_override_list = self._flatpak_api.get_override_filesystems(
                app_id
            )
            for filesystem_override_loop in filesystem_override_list:
                export_loop.add_override_filesystem(filesystem_override_loop)

            export_data_list.append(export_loop.get_object())

        self._system_api.write_json_file(path, export_data_list)
