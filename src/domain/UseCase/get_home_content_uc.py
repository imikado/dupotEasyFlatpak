from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flathub_api_contract import FlathubApiContract
from domain.contract.system_api_contract import SystemApiContract
from domain.entity.api_cache_entity import ApiCacheEntity
from domain.entity.appstream_short_entity import AppstreamShortEntity


class GetHomeContentUC:

    _api_cache_repository: ApiCacheRepositoryContract
    _appstream_repository: AppstreamRepositoryContract
    _flathub_api: FlathubApiContract
    _system_api: SystemApiContract

    NB_DAYS_SHOULD_SYNC_HOME = 3

    def __init__(
        self,
        api_cache_repository: ApiCacheRepositoryContract,
        appstream_repository: AppstreamRepositoryContract,
        flathub_api: FlathubApiContract,
        system_api: SystemApiContract,
    ):
        self._api_cache_repository = api_cache_repository
        self._appstream_repository = appstream_repository
        self._flathub_api = flathub_api
        self._system_api = system_api

        self.load()

    def load(self):
        if self.should_sync_from_api():
            print("sync from api")

            app_id_list_in_api = self._flathub_api.get_trending_apps()
            if len(app_id_list_in_api):
                self.update_app_id_list_in_cache(
                    ApiCacheRepositoryContract.ID_TRENDING, app_id_list_in_api
                )

            app_id_list_in_api = self._flathub_api.get_popular_apps()
            if len(app_id_list_in_api):
                self.update_app_id_list_in_cache(
                    ApiCacheRepositoryContract.ID_POPULAR, app_id_list_in_api
                )

            app_id_list_in_api = self._flathub_api.get_updated_apps()
            if len(app_id_list_in_api):
                self.update_app_id_list_in_cache(
                    ApiCacheRepositoryContract.ID_RECENTLY_UPD, app_id_list_in_api
                )

            app_id_list_in_api = self._flathub_api.get_added_apps()
            if len(app_id_list_in_api):
                self.update_app_id_list_in_cache(
                    ApiCacheRepositoryContract.ID_RECENTLY_ADDED, app_id_list_in_api
                )

            api_cache_parameters = self.get_entity_in_cache()
            parameters_object = api_cache_parameters.update_home_api_updated_timestamp(
                self.get_current_timestamp()
            )

            print(parameters_object)

            self.update_parameters_in_cache(parameters_object)

        pass

    def store_missing_added_apps(self):

        recently_app_id_list = self._flathub_api.get_added_apps()

        app_id_list_already_stored = []

        appstream_list_already_stored = self._appstream_repository.get_list_by_id_list(
            recently_app_id_list
        )
        for appstream_loop in appstream_list_already_stored:
            app_id_list_already_stored.append(appstream_loop.id)

        missing_app_id_list = []

        for recently_id_loop in recently_app_id_list:
            if recently_id_loop not in app_id_list_already_stored:
                missing_app_id_list.append(recently_id_loop)

    def get_app_from_cache_by_id_list(self, api_cache_id) -> list[AppstreamShortEntity]:
        app_id_list_in_cache = self.get_app_id_list_in_cache(api_cache_id)
        if len(app_id_list_in_cache):
            return self._appstream_repository.get_list_by_id_list(app_id_list_in_cache)

        return []

    def get_trending_appstream_list(self) -> list[AppstreamShortEntity]:

        return self.get_app_from_cache_by_id_list(
            ApiCacheRepositoryContract.ID_TRENDING
        )

    def get_popular_appstream_list(self) -> list[AppstreamShortEntity]:

        return self.get_app_from_cache_by_id_list(ApiCacheRepositoryContract.ID_POPULAR)

    def get_updated_appstream_list(self) -> list[AppstreamShortEntity]:

        return self.get_app_from_cache_by_id_list(
            ApiCacheRepositoryContract.ID_RECENTLY_UPD
        )

    def get_added_appstream_list(self) -> list[AppstreamShortEntity]:

        return self.get_app_from_cache_by_id_list(
            ApiCacheRepositoryContract.ID_RECENTLY_ADDED
        )

    def get_app_id_list_in_cache(self, cache_id) -> list:

        api_cache = self._api_cache_repository.get_by_id(cache_id)
        if api_cache is None:
            return []

        return api_cache.get_app_id_list()

    def get_entity_in_cache(self) -> ApiCacheEntity:
        api_cache = self._api_cache_repository.get_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS
        )
        if api_cache is None:
            return object

        return api_cache

    def update_app_id_list_in_cache(self, cache_id, app_id_list: list[str]) -> list:
        self._api_cache_repository.update_by_id(cache_id, app_id_list)

    def update_parameters_in_cache(self, parameters: object):
        self._api_cache_repository.update_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS, parameters
        )

    def should_sync_from_api(self) -> bool:
        api_cache_parameters = self._api_cache_repository.get_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS
        )

        if api_cache_parameters is None:
            return True

        if (
            self.get_current_timestamp()
            - api_cache_parameters.get_home_api_updated_timestamp()
        ) > self.seconds_from_days(self.NB_DAYS_SHOULD_SYNC_HOME):
            return True

        return False

    def seconds_from_days(self, days) -> int:
        return days * 24 * 60 * 60

    def get_current_timestamp(self) -> int:
        return self._system_api.get_datetime_current_timestamp()
