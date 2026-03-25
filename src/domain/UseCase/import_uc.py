from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.contract.recipe_repository_contract import RecipeRepositoryContract
from domain.contract.system_api_contract import SystemApiContract
from domain.entity.appstream_short_entity import AppstreamShortEntity
from domain.entity.import_entity import ImportEntity
from domain.entity.process_call_entity import ProcessCallEntity


class ImportUc:

    _system_api: SystemApiContract
    _flatpak_api: FlatpakApiContract
    _recipe_repository = RecipeRepositoryContract
    _appstream_repository = AppstreamRepositoryContract

    _app_id_list: list[str] = []

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

    def get_list(self, path: str) -> list[ImportEntity]:
        raw_import_app_list = self._system_api.read_json_file_obj_list(path)

        import_list: list[ImportEntity] = []

        for raw_import_app_loop in raw_import_app_list:

            self._app_id_list.append(raw_import_app_loop["app_id"])
            import_list.append(ImportEntity(raw_import_app_loop))

        return import_list

    def get_appstream_list(self, path: str) -> list[ImportEntity]:
        import_list = self.get_list(path)
        indexed_appstream_list = self.get_indexed_appstream_list_with_id_list(
            self._app_id_list
        )

        for import_loop in import_list:
            if import_loop.app_id.lower() in indexed_appstream_list:
                appstream_found: AppstreamShortEntity = indexed_appstream_list[
                    import_loop.app_id.lower()
                ]
                import_loop.name = appstream_found.name
                import_loop.summary = appstream_found.summary
                import_loop.icon = appstream_found.getIcon()

        return import_list

    def get_indexed_appstream_list_with_id_list(
        self, app_id_list: list[str]
    ) -> list[AppstreamShortEntity]:
        appstream_list = self._appstream_repository.get_list_by_id_list(app_id_list)

        indexed_list = {}
        for appstream_loop in appstream_list:
            indexed_list[appstream_loop.id.lower()] = appstream_loop

        return indexed_list

    def get_filtered_list(
        self, import_list: list[ImportEntity], filtered_id_list: list[str]
    ):

        filtered_list: list[ImportEntity] = []

        for import_loop in import_list:
            if import_loop.app_id in filtered_id_list:
                filtered_list.append(import_loop)

        return filtered_list

    def process(self, import_list: list[ImportEntity]) -> list[ProcessCallEntity]:

        process_call_list: list[ProcessCallEntity] = []

        for import_loop in import_list:

            process_call = ProcessCallEntity(
                self._flatpak_api.get_install_call(
                    import_loop.app_id, f"--{import_loop.installation_scope}"
                )
            )

            process_call_list.append(process_call)

        return process_call_list
