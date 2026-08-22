from domain.conf.path_conf import PathConf
from domain.entity.local_app_entity import LocalAppEntity
from infrastructure.api.system_api import SystemApi


class LocalAppsRepository():

    _system_api: SystemApi
    _local_app_list: list[LocalAppEntity]
    _source_path:str

    def __init__(self):
        super().__init__()

        self._system_api = SystemApi()
        self._local_app_list = []
        self._source_path:str=PathConf().get_local_app_list_path()
        if not self.get_system_api().file_exists(self.get_source_path()):
            return

        raw_list = self.get_system_api().read_json_file_obj_list(
            self.get_source_path()
        )

        for raw_loop in raw_list:
            self._local_app_list.append(LocalAppEntity(raw_loop))

    def get_source_path(self)->str:
        return self._source_path

    def get_system_api(self)->SystemApi:
        return self._system_api

    def get_list(self) -> list[LocalAppEntity]:
        return self._local_app_list

    def get_by_id(self, id: str) -> LocalAppEntity:
        for local_app_loop in self._local_app_list:
            if local_app_loop.id == id:
                return local_app_loop

    def find_by_name_or_url(self, name: str, url: str) -> LocalAppEntity:
        """Case-insensitive lookup by name and/or url — used to avoid
        inserting a duplicate entry for an app already tracked under a
        different id (e.g. same GitHub URL typed with different casing)."""
        name_normalized = (name or "").strip().lower()
        url_normalized = (url or "").strip().lower().rstrip("/")
        for local_app_loop in self._local_app_list:
            if name_normalized and local_app_loop.name.strip().lower() == name_normalized:
                return local_app_loop
            if url_normalized and local_app_loop.url.strip().lower().rstrip("/") == url_normalized:
                return local_app_loop


    def insert_or_update(self,id:str,name:str,url:str,version:str):
        found=False
        for local_app_loop in self._local_app_list:
            if local_app_loop.id == id:
                local_app_loop.name=name
                local_app_loop.url=url
                local_app_loop.version=version
                                
                return self.save()

        if not found:
            self._local_app_list.append(
                LocalAppEntity({LocalAppEntity.FIELD_ID: id, LocalAppEntity.FIELD_NAME: name,LocalAppEntity.FIELD_URL: url,LocalAppEntity.FIELD_VERSION: version})
            )
            return self.save()

    def insert_or_update_deduped(self, id: str, name: str, url: str, version: str):
        """Same as insert_or_update, but first checks whether an entry with
        the same name and/or GitHub url already exists under a different id
        (e.g. same project typed with different URL casing) and updates that
        one in place instead of creating a duplicate row."""
        existing = self.find_by_name_or_url(name, url)
        target_id = existing.id if existing else id
        return self.insert_or_update(target_id, name, url, version)

    def delete(self,id:str):
        filtered_list=[]
        for local_app_loop in self._local_app_list:
            if local_app_loop.id != id:
                filtered_list.append(local_app_loop)
        self._local_app_list=filtered_list
        self.save()
        


    def save(self):
        self.get_system_api().write_json_file(
            self.get_source_path(),
            [local_app_loop.to_dict() for local_app_loop in self._local_app_list],
        )






