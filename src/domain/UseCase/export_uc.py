from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.contract.recipe_repository_contract import RecipeRepositoryContract
from domain.contract.system_api_contract import SystemApiContract
from domain.entity.export_entity import ExportEntity


class ExportUc:

    _system_api: SystemApiContract
    _flatpak_api: FlatpakApiContract
    _recipe_repository = RecipeRepositoryContract

    def __init__(
        self,
        system_api: SystemApiContract,
        flatpak_api: FlatpakApiContract,
        recipe_repository: RecipeRepositoryContract,
    ):
        self._system_api = system_api
        self._flatpak_api = flatpak_api
        self._recipe_repository = recipe_repository

    def export(self, path: str):
        app_ids = self._flatpak_api.get_installed_app_id_list()
        export_data_list = []
        for app_id in app_ids:

            installation_scope = self._flatpak_api.get_installation_scope(app_id)

            export_loop = ExportEntity(app_id, installation_scope)

            filesystem_override_list = self._flatpak_api.get_override_filesystems(
                app_id
            )
            for filesystem_override_loop in filesystem_override_list:
                export_loop.add_override_filesystem(filesystem_override_loop)

            export_data_list.append(export_loop.get_object())

        self._system_api.write_json_file(path, export_data_list)
