from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flathub_api_contract import FlathubApiContract
from domain.entity.appstream_short_entity import AppstreamShortEntity
 

class GetHomeContentUC:

    _api_cache_repository:ApiCacheRepositoryContract
    _appstream_repository:AppstreamRepositoryContract
    _flathub_api:FlathubApiContract


    def __init__(self, api_cache_repository: ApiCacheRepositoryContract, appstream_repository: AppstreamRepositoryContract, flathub_api: FlathubApiContract):
        self._api_cache_repository = api_cache_repository
        self._appstream_repository= appstream_repository
        self._flathub_api= flathub_api


    def get_trending_appstream_list(self)->list[AppstreamShortEntity]:

        api_cache_id=ApiCacheRepositoryContract.ID_TRENDING

        app_id_list_in_cache=self.get_app_id_list_in_cache(api_cache_id)
        if len(app_id_list_in_cache):
            return self._appstream_repository.get_by_id_list(app_id_list_in_cache)
        
        app_id_list_in_api = self._flathub_api.get_trending_apps
        if len(app_id_list_in_api):
            self.update_app_id_list_in_cache(api_cache_id,app_id_list_in_api)

            return self._appstream_repository.get_by_id_list(app_id_list_in_api)


    def get_app_id_list_in_cache(self,cache_id)->list:
        api_cache = self._api_cache_repository.get_by_id(cache_id)
        if api_cache is None:
            return []
        
        return api_cache.get_app_id_list()
    
    def update_app_id_list_in_cache(self,cache_id,app_id_list:list[str])->list:
        self._api_cache_repository.update_by_id(cache_id,app_id_list)