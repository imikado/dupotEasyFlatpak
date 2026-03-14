from abc import abstractmethod

from domain.entity.bundle_entity import BundleEntity


class BundleRepositoryContract:

    @abstractmethod
    def get_list(self) -> list[BundleEntity]:
        pass

    @abstractmethod
    def get_by_id(self, id: str) -> BundleEntity:
        pass
