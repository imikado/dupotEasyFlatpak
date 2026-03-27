from abc import ABC, abstractmethod

from domain.entity.appstream_short_entity import AppstreamShortEntity


class AppstreamRepositoryContract(ABC):

    @abstractmethod
    def get_by_id(self, id: str) -> AppstreamShortEntity | None:
        pass

    @abstractmethod
    def get_all_app_id_lastupdate_list(self) -> list[object]:
        pass

    @abstractmethod
    def get_id_and_lastupdate_list_by_id_list(self, ids: list[str]) -> list[object]:
        pass

    @abstractmethod
    def get_list_by_id_list(self, ids: list[str]) -> list[AppstreamShortEntity]:
        pass

    @abstractmethod
    def get_list_by_category_id(self, category_id: str) -> list[AppstreamShortEntity]:
        pass

    @abstractmethod
    def get_list_by_category_id_and_search(
        self, category_id: str, search: str
    ) -> list[AppstreamShortEntity]:
        pass

    @abstractmethod
    def get_list_by_seach(self, search: str) -> list[AppstreamShortEntity]:
        pass

    @abstractmethod
    def get_summary_list_by_category_id(
        self, category_id: str
    ) -> list[AppstreamShortEntity]:
        pass

    @abstractmethod
    def insert_from_raw_object(self, raw_obj: object):
        pass

    @abstractmethod
    def update_from_raw_object_with_id(self, id: str, raw_obj: object):
        pass
