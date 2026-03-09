from abc import ABC, abstractmethod

from domain.entity.appstream_short_entity import AppstreamShortEntity


class AppstreamRepositoryContract(ABC):

    @abstractmethod
    def get_by_id(self, id: str) -> AppstreamShortEntity | None:
        pass

    @abstractmethod
    def get_list_by_id_list(self, ids: list[str]) -> list[AppstreamShortEntity]:
        pass

    @abstractmethod
    def get_list_by_category_id(self, category_id: str) -> list[AppstreamShortEntity]:
        pass

    @abstractmethod
    def get_list_by_seach(self, search: str) -> list[AppstreamShortEntity]:
        pass
