from domain.conf.path_conf import PathConf
from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flathub_api_contract import FlathubApiContract
from domain.contract.system_api_contract import SystemApiContract


class UpdateDatabaseFromApiUc:

    LAST_SYNC_MAX_DAYS = 3

    _flathub_api: FlathubApiContract
    _appstream_repository: AppstreamRepositoryContract
    _system_api: SystemApiContract
    _api_cache_repository: ApiCacheRepositoryContract
    _lang:str

    def __init__(
        self,
        flathub_api: FlathubApiContract,
        appstream_repository: AppstreamRepositoryContract,
        system_api: SystemApiContract,
        api_cache_repository: ApiCacheRepositoryContract,
        lang:str
    ):
        self._flathub_api = flathub_api
        self._appstream_repository = appstream_repository
        self._system_api = system_api
        self._api_cache_repository = api_cache_repository
        self._lang=lang

    def process(self):

        print(f"[sync] lang={self._lang!r} should_sync={self.should_sync_api()}")

        if not self.should_sync_api():
            return

        print("need to sync from api")

        try:
            self._process()
        except Exception as e:
            import traceback

            print(f"[sync] ERROR: {e}")
            traceback.print_exc()

    def _process(self):

        app_id_to_check_in_db_list = []

        api_cache_entity = self._api_cache_repository.get_by_id(
            ApiCacheRepositoryContract.ID_APPS_OF_WEEK
        )

        app_id_of_the_week_list = api_cache_entity.get_app_id_list()
        print(f"[sync] apps of the week: {app_id_of_the_week_list}")
        for app_id_of_the_week_loop in app_id_of_the_week_list:
            app_id_to_check_in_db_list.append(app_id_of_the_week_loop)

        recently_raw_appstream_list = self._flathub_api.get_added_appstreams()
        for recently_raw_appstream_loop in recently_raw_appstream_list:
            app_id_to_check_in_db_list.append(recently_raw_appstream_loop["app_id"])

        app_id_list_already_stored = []

        appstream_list_already_stored = self._appstream_repository.get_list_by_id_list(
            app_id_to_check_in_db_list
        )
        for appstream_loop in appstream_list_already_stored:
            app_id_list_already_stored.append(appstream_loop.id.lower())

        icons_path = PathConf().get_icons_path()

        for recently_raw_appstream_loop in recently_raw_appstream_list:

            id_loop: str = recently_raw_appstream_loop["app_id"]

            if id_loop.lower() not in app_id_list_already_stored:
                self._appstream_repository.insert_from_raw_object(
                    recently_raw_appstream_loop
                )
            else:
                self._appstream_repository.update_name_summary_by_id(
                    id_loop,
                    recently_raw_appstream_loop["name"],
                    recently_raw_appstream_loop["summary"],
                )

            icon_url = recently_raw_appstream_loop.get("icon", "")
            if icon_url:
                icon_path = f"{icons_path}/{id_loop.lower()}.png"
                if not self._system_api.file_exists(icon_path):
                    self._system_api.download_remote_file_to(icon_url, icon_path)

        for app_id_of_the_week_loop in app_id_of_the_week_list:
            if app_id_of_the_week_loop.lower() not in app_id_list_already_stored:

                self._appstream_repository.insert_missing_app_id(
                    app_id_of_the_week_loop
                )

            detail = self._flathub_api.get_appstream_by_id(app_id_of_the_week_loop)
            print(f"[sync] {app_id_of_the_week_loop} -> {detail.get('name') if detail else 'FETCH FAILED (None)'}")
            if detail:
                self._appstream_repository.update_from_raw_object_with_id(
                    app_id_of_the_week_loop, detail
                )

        self.update_sync_api(self._lang)
        print("[sync] done, last_lang updated to " + self._lang)

    def should_sync(self, last_update) -> bool:

        if (
            last_update + self.LAST_SYNC_MAX_DAYS * 60 * 60 * 24
        ) < self._system_api.get_datetime_current_timestamp():

            return True
        return False

    def should_sync_api(self) -> bool:
        api_cache_parameter_entity = self._api_cache_repository.get_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS
        )

        if(api_cache_parameter_entity.get_api_last_lang()!=self._lang):
            return True

        last_timestamp_update = api_cache_parameter_entity.get_api_last_sync_timestamp()
        return self.should_sync(last_timestamp_update)

    def update_sync_api(self,lang:str):
        api_cache_parameter_entity = self._api_cache_repository.get_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS
        )
        api_cache_parameter_entity.update_api_last_sync_timestamp(
            self._system_api.get_datetime_current_timestamp(),
            lang
        )

        self._api_cache_repository.update_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS,
            api_cache_parameter_entity.get_content_as_object(),
        )
