from domain.conf.path_conf import PathConf
from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flathub_api_contract import FlathubApiContract
from domain.contract.system_api_contract import SystemApiContract
from domain.entity.appstream_short_entity import AppstreamShortEntity


class GetSearchContentUc:

    _appstream_repository: AppstreamRepositoryContract

    def __init__(
        self,
        appstream_repository: AppstreamRepositoryContract,
        flathub_api: FlathubApiContract = None,
        system_api: SystemApiContract = None,
    ):
        self._appstream_repository = appstream_repository
        self._flathub_api = flathub_api
        self._system_api = system_api

    def get_app_list_by_search(self, search: str) -> list[AppstreamShortEntity]:
        return self._appstream_repository.get_list_by_seach(search)

    def get_app_list_from_api(self, search: str) -> list[AppstreamShortEntity]:
        if not self._flathub_api:
            return []

        raw_hits = self._flathub_api.search_apps(search)
        if not raw_hits:
            return []

        ids = [h["app_id"] for h in raw_hits]
        already_in_db = {
            e.id.lower()
            for e in self._appstream_repository.get_list_by_id_list(ids)
        }

        icons_path = PathConf().get_icons_path()
        results = []

        for hit in raw_hits:
            app_id = hit["app_id"]
            if app_id.lower() not in already_in_db:
                self._appstream_repository.insert_from_raw_object(hit)
                if self._system_api:
                    icon_url = hit.get("icon", "")
                    if icon_url:
                        icon_path = f"{icons_path}/{app_id.lower()}.png"
                        if not self._system_api.file_exists(icon_path):
                            self._system_api.download_remote_file_to(icon_url, icon_path)

            results.append(
                AppstreamShortEntity(
                    app_id,
                    hit.get("name", ""),
                    hit.get("icon", ""),
                    hit.get("summary", ""),
                    None,
                )
            )

        return results
