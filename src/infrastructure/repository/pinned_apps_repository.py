from domain.conf.path_conf import PathConf
from domain.entity.pinned_app_entity import PinnedAppEntity
from infrastructure.api.system_api import SystemApi


class PinnedAppsRepository():

    _system_api: SystemApi
    _pinned_app_list: list[PinnedAppEntity]
    _source_path:str

    def __init__(self):
        super().__init__()

        self._system_api = SystemApi()
        self._pinned_app_list = []
        self._source_path:str=PathConf().get_pinned_app_list_path()
        if not self.get_system_api().file_exists(self.get_source_path()):
            return

        raw_list = self.get_system_api().read_json_file_obj_list(
            self.get_source_path()
        )

        for raw_loop in raw_list:
            self._pinned_app_list.append(PinnedAppEntity(raw_loop))

    def get_source_path(self)->str:
        return self._source_path

    def get_system_api(self)->SystemApi:
        return self._system_api

    def get_list(self) -> list[PinnedAppEntity]:
        return self._pinned_app_list

    def get_by_id(self, id: str) -> PinnedAppEntity:
        for pinned_app_loop in self._pinned_app_list:
            if pinned_app_loop.id == id:
                return pinned_app_loop

    def has_id(self,id:str)->bool:
        for pinned_app_loop in self._pinned_app_list:
            if pinned_app_loop.id == id:
                return True
        return False

    def get_app_id_list(self)->list[str]:
        app_id_list:list[str]=[]
        for pinned_app_loop in self._pinned_app_list:
            app_id_list.append(pinned_app_loop.id)

        return app_id_list

    def insert_or_update(self,id:str,commit:str):
        found=False
        for pinned_app_loop in self._pinned_app_list:
            if pinned_app_loop.id == id:
                pinned_app_loop.commit=commit
                return self.save()

        if not found:
            self._pinned_app_list.append(
                PinnedAppEntity({PinnedAppEntity.FIELD_ID: id, PinnedAppEntity.FIELD_COMMIT: commit})
            )
            return self.save()

    def delete(self,id:str):
        filtered_list=[]
        for pinned_app_loop in self._pinned_app_list:
            if pinned_app_loop.id != id:
                filtered_list.append(pinned_app_loop)
        self._pinned_app_list=filtered_list
        self.save()
        


    def save(self):
        self.get_system_api().write_json_file(
            self.get_source_path(),
            [pinned_app_loop.to_dict() for pinned_app_loop in self._pinned_app_list],
        )






