from abc import ABC, abstractmethod

from domain.entity.api_cache_entity import ApiCacheEntity


class ApiCacheRepositoryContract(ABC):

    ID_TRENDING = "trendingApi"
    ID_POPULAR = "popularApi"
    ID_RECENTLY_UPD = "recentlyUpdatedApi"
    ID_RECENTLY_ADDED = "recentlyAddedApi"
    ID_APPS_OF_WEEK = "appsOfTheWeek"

    ID_PARAMETERS = "parameters"

    # Negative-lookup cache for OCI registry enrichment: {"repo_id/app_id": last_attempt_timestamp}
    ID_OCI_MISSES = "ociMisses"

    @abstractmethod
    def get_by_id(self, id: str) -> ApiCacheEntity | None:
        pass

    @abstractmethod
    def update_by_id(self, id: str, content_value: any) -> ApiCacheEntity | None:
        pass
