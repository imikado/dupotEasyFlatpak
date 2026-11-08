from concurrent.futures import ThreadPoolExecutor

from domain.conf.path_conf import PathConf
from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flathub_api_contract import FlathubApiContract
from domain.contract.system_api_contract import SystemApiContract


class SyncDatabaseFromApiUc:
    """Full Flathub sync of the shipped asset DB + icons (developer tool,
    see syncFlathubApi.sh). Network calls run in a thread pool, DB writes
    stay on the calling thread."""

    REPO_FLATHUB = "flathub"

    def __init__(
        self,
        flathub_api: FlathubApiContract,
        appstream_repository: AppstreamRepositoryContract,
        system_api: SystemApiContract,
        workers: int = 8,
        log=print,
    ):
        self._flathub_api = flathub_api
        self._appstream_repository = appstream_repository
        self._system_api = system_api
        self._workers = workers
        self._log = log

    # ------------------------------------------------------------ steps

    def get_api_app_id_list(self) -> list[str]:
        return list(self._flathub_api.get_all_app_id_list())

    def process_insert_missing(self, api_app_id_list: list[str]) -> list[str]:
        db_ids = {i.lower() for i in self._appstream_repository.get_all_app_id_list()}
        missing = [i for i in api_app_id_list if i.lower() not in db_ids]
        self._log(f"new applications: {len(missing)}")
        inserted = []
        for app_id, detail in self._fetch_details(missing):
            if not detail:
                self._log(f"  skip {app_id}: no appstream")
                continue
            self._appstream_repository.insert_missing_app_id(app_id, self.REPO_FLATHUB)
            self._appstream_repository.update_from_raw_object_with_id(app_id, detail)
            inserted.append(app_id)
        return inserted

    def process_update(self, app_id_list: list[str] | None = None) -> int:
        if app_id_list is None:
            app_id_list = self._appstream_repository.get_all_app_id_list()
        self._log(f"refreshing applications: {len(app_id_list)}")
        count = 0
        for app_id, detail in self._fetch_details(app_id_list):
            if detail:
                self._appstream_repository.update_from_raw_object_with_id(app_id, detail)
                count += 1
        return count

    def process_missing_icons(self, refresh: bool = False) -> int:
        icons_path = PathConf().get_icons_path()
        todo = []
        for app in self._appstream_repository.get_all_icon_list():
            if not app["icon"] or not str(app["icon"]).startswith("http"):
                continue
            path = f"{icons_path}/{app['id'].lower()}.png"
            if refresh or not self._system_api.file_exists(path):
                todo.append((app["icon"], path))
        self._log(f"icons to download: {len(todo)}")
        with ThreadPoolExecutor(self._workers) as pool:
            results = list(pool.map(lambda t: self._system_api.download_remote_file_to(*t), todo))
        return sum(1 for r in results if r)

    def get_removed_app_id_list(self, api_app_id_list: list[str]) -> list[str]:
        api_ids = {i.lower() for i in api_app_id_list}
        return [
            row["id"]
            for row in self._appstream_repository.get_id_and_repo_list()
            if row["id"].lower() not in api_ids and row["repos"] == [self.REPO_FLATHUB]
        ]

    def process_prune(self, removed_app_id_list: list[str]) -> int:
        icons_path = PathConf().get_icons_path()
        for app_id in removed_app_id_list:
            self._appstream_repository.delete_by_id(app_id)
            path = f"{icons_path}/{app_id.lower()}.png"
            if self._system_api.file_exists(path):
                self._system_api.remove_file(path)
        return len(removed_app_id_list)

    # ------------------------------------------------------------ helpers

    def _fetch_detail(self, app_id: str):
        try:
            detail = self._flathub_api.get_appstream_by_id(app_id)
            if not detail:
                return app_id, None
            summary = self._flathub_api.get_summary_by_id(app_id)
            return app_id, self.enrich_appstream(detail, summary)
        except Exception as e:
            self._log(f"  error {app_id}: {e}")
            return app_id, None

    def _fetch_details(self, app_id_list: list[str]):
        total = len(app_id_list)
        with ThreadPoolExecutor(self._workers) as pool:
            for index, result in enumerate(pool.map(self._fetch_detail, app_id_list), 1):
                if index % 100 == 0 or index == total:
                    self._log(f"  {index}/{total}")
                yield result

    def enrich_appstream(self, appstream_obj: dict, summary_obj: dict | None) -> dict:
        if summary_obj:
            for field in ["download_size", "installed_size", "arches"]:
                if summary_obj.get(field) not in (None, ""):
                    appstream_obj[field] = summary_obj[field]
        return appstream_obj
