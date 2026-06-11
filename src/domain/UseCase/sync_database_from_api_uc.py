from domain.conf.path_conf import PathConf
from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flathub_api_contract import FlathubApiContract
from domain.contract.system_api_contract import SystemApiContract


class SyncDatabaseFromApiUc:

    
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
        self.process_insert_missing()
        self.process_update()
    
    def process_insert_missing(self):

        app_id_list_from_database=self._appstream_repository.get_all_app_id_list()

        app_id_list_from_api= self._flathub_api.get_all_app_id_list()
        for app_id_from_api_loop in app_id_list_from_api:
            if app_id_from_api_loop in app_id_list_from_database:
                continue

            detail_loop=self._flathub_api.get_appstream_by_id(app_id_from_api_loop)

            icons_path = PathConf().get_icons_path()
            icon_url = detail_loop.get("icon", "")
            if icon_url:
                icon_path = f"{icons_path}/{app_id_from_api_loop.lower()}.png"
                if not self._system_api.file_exists(icon_path):
                    self._system_api.download_remote_file_to(icon_url, icon_path)

            self._appstream_repository.insert_missing_app_id(app_id_from_api_loop)


    def process_update(self):

        app_id_list_from_database=self._appstream_repository.get_all_app_id_list()
        for app_id_from_database_loop in app_id_list_from_database:
            summary_loop=self._flathub_api.get_summary_by_id(app_id_from_database_loop)
            detail_loop=self._flathub_api.get_appstream_by_id(app_id_from_database_loop)

            enriched_appstream_loop=self.enrich_appstream(detail_loop,summary_loop)

            self._appstream_repository.update_from_raw_object_with_id(app_id_from_database_loop,enriched_appstream_loop)


    def enrich_appstream(self,appstream_obj:object,summary_obj:object):
        
        for summary_field_loop in ['download_size','installed_size','arches']:
            if summary_obj[summary_field_loop]!='':
                appstream_obj[summary_field_loop]=summary_obj[summary_field_loop]

        return appstream_obj