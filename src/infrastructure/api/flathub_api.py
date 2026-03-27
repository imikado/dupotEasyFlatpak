import urllib.request
import urllib.error
import json

from domain.contract.flathub_api_contract import FlathubApiContract


class FlathubApi(FlathubApiContract):

    _BASE_URL = "https://flathub.org/api/v2"

    def get_trending_apps(
        self, page: int = 0, per_page: int = 20, locale: str = "en"
    ) -> list:
        url = f"{self._BASE_URL}/collection/trending?page={page}&per_page={per_page}&locale={locale}"
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
        return [hit["app_id"] for hit in data.get("hits", [])]

    def get_popular_apps(
        self, page: int = 0, per_page: int = 20, locale: str = "en"
    ) -> list:
        url = f"{self._BASE_URL}/collection/popular?page={page}&per_page={per_page}&locale={locale}"
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
        return [hit["app_id"] for hit in data.get("hits", [])]

    def get_updated_apps(
        self, page: int = 0, per_page: int = 20, locale: str = "en"
    ) -> list:
        url = f"{self._BASE_URL}/collection/recently-updated?page={page}&per_page={per_page}&locale={locale}"
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
        return [hit["app_id"] for hit in data.get("hits", [])]

    def get_added_apps(
        self, page: int = 0, per_page: int = 20, locale: str = "en"
    ) -> list:
        url = f"{self._BASE_URL}/collection/recently-added?page={page}&per_page={per_page}&locale={locale}"
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
        return [hit["app_id"] for hit in data.get("hits", [])]

    def get_added_appstreams(
        self, page: int = 0, per_page: int = 50, locale: str = "en"
    ) -> list[object]:
        url = f"{self._BASE_URL}/collection/recently-added?page={page}&per_page={per_page}&locale={locale}"
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
        return data.get("hits", [])

    def get_appstream_by_id(self, id: str) -> object | None:
        url = f"{self._BASE_URL}/appstream/{id}"
        try:
            with urllib.request.urlopen(url) as response:
                return json.loads(response.read().decode())
        except (urllib.error.URLError, urllib.error.HTTPError):
            return None

    def get_app_id_list_of_the_week(self, date: str) -> list[str]:
        url = f"{self._BASE_URL}/app-picks/apps-of-the-week/{date}"
        app_id_list = []
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            for app_loop in data["apps"]:
                app_id_list.append(app_loop["app_id"])

        return app_id_list
