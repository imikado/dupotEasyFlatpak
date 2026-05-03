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

    @abstractmethod
    def get_added_apps(
        self, page: int = 0, per_page: int = 8, locale: str = "en"
    ) -> list:
        pass

    @abstractmethod
    def get_added_appstreams(
        self, page: int = 0, per_page: int = 50, locale: str = "en"
    ) -> list[object]:
        pass

    @abstractmethod
    def get_appstream_by_id(self, id: str) -> object | None:
        pass

    @abstractmethod
    def get_app_id_list_of_the_week(self, date: str) -> list[str]:
        pass

    @abstractmethod
    def search_apps(self, query: str) -> list[object]:
        pass
