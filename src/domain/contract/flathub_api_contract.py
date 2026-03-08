from abc import ABC, abstractmethod


class FlathubApiContract(ABC):

    @abstractmethod
    def get_trending_apps(
        self, page: int = 0, per_page: int = 8, locale: str = "en"
    ) -> list:
        pass

    @abstractmethod
    def get_popular_apps(
        self, page: int = 0, per_page: int = 8, locale: str = "en"
    ) -> list:
        pass

    @abstractmethod
    def get_updated_apps(
        self, page: int = 0, per_page: int = 8, locale: str = "en"
    ) -> list:
        pass
