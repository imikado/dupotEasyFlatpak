from domain.conf.path_conf import PathConf
from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flathub_api_contract import FlathubApiContract
from domain.contract.system_api_contract import SystemApiContract


class UpdateDatabaseFromApiUc:

    LAST_UPDATE_MAX_DAYS = 7

    _flathub_api: FlathubApiContract
    _appstream_repository: AppstreamRepositoryContract
    _system_api: SystemApiContract

    def __init__(
        self,
        flathub_api: FlathubApiContract,
        appstream_repository: AppstreamRepositoryContract,
        system_api: SystemApiContract,
    ):
        self._flathub_api = flathub_api
        self._appstream_repository = appstream_repository
        self._system_api = system_api

    def process(self):

        recently_raw_appstream_list = self._flathub_api.get_added_appstreams()
        recently_app_id_list = []
        for recently_raw_appstream_loop in recently_raw_appstream_list:
            recently_app_id_list.append(recently_raw_appstream_loop["app_id"])

        app_id_list_already_stored = []

        appstream_list_already_stored = self._appstream_repository.get_list_by_id_list(
            recently_app_id_list
        )
        for appstream_loop in appstream_list_already_stored:
            app_id_list_already_stored.append(appstream_loop.id)

        for recently_raw_appstream_loop in recently_raw_appstream_list:

            id_loop: str = recently_raw_appstream_loop["app_id"]

            if id_loop not in app_id_list_already_stored:

                self._appstream_repository.insert_from_raw_object(
                    recently_raw_appstream_loop
                )

        apps_stored_list = self._appstream_repository.get_all_app_id_lastupdate_list()
        for app_stored_loop in apps_stored_list:

            id_loop = app_stored_loop["id"]
            lastupdate_loop = app_stored_loop["lastUpdate"]

            if not self.should_update(lastupdate_loop):
                continue

            raw_obj_loop = self._flathub_api.get_appstream_by_id(id_loop)

            if raw_obj_loop is None:
                continue

            print(f"{id_loop} update \n")
            self._appstream_repository.update_from_raw_object_with_id(
                id_loop, raw_obj_loop
            )

            if "icon" in raw_obj_loop:

                self._system_api.download_remote_file_to(
                    raw_obj_loop["icon"],
                    f"{PathConf().get_icons_path()}/{id_loop.lower()}.png",
                )

    def should_update(self, last_update) -> bool:
        if (
            last_update + self.LAST_UPDATE_MAX_DAYS * 60 * 60 * 24
        ) < self._system_api.get_datetime_current_timestamp():

            return True
        return False
