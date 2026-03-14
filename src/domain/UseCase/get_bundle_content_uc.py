from domain.contract.bundle_repository_contract import BundleRepositoryContract
from domain.entity.bundle_entity import BundleEntity


class GetBundleContentUc:

    _bundle_repository: BundleRepositoryContract

    def __init__(self, bundle_repository: BundleRepositoryContract):
        self._bundle_repository = bundle_repository
        pass

    def get_list(self) -> list[BundleEntity]:
        return self._bundle_repository.get_list()
