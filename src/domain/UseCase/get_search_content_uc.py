from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.category_repository_contract import CategoryRepositoryContract
from domain.entity.appstream_short_entity import AppstreamShortEntity


class GetSearchContentUc:

    _appstream_repository: AppstreamRepositoryContract

    def __init__(self, appstream_repository: AppstreamRepositoryContract):
        self._appstream_repository = appstream_repository
        pass

    def get_app_list_by_search(self, search: str) -> list[AppstreamShortEntity]:

        return self._appstream_repository.get_list_by_seach(search)
