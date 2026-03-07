from abc import ABC, abstractmethod

from domain.entity.api_cache_entity import ApiCacheEntity


class ApiCacheRepositoryContract(ABC):

    ID_TRENDING='trendingApi'
    ID_POPULAR='popularApi'
    ID_RECENTLY_UPD='recentlyUpdatedApi'

    @abstractmethod
    def get_by_id(self, id: str) -> ApiCacheEntity | None:
        pass

   