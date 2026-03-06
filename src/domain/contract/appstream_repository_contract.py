from abc import ABC, abstractmethod

from domain.entity.appstream_short_entity import AppstreamShortEntity


class AppstreamRepositoryContract(ABC):

    @abstractmethod
    def get_by_id(self, id: str) -> AppstreamShortEntity | None:
        pass

    @abstractmethod
    def get_by_id_list(self, ids: list[str]) -> list[AppstreamShortEntity]:
        pass
