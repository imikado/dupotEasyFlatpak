from abc import ABC, abstractmethod


class OciApiContract(ABC):

    @abstractmethod
    def get_enrichment_by_app_id(self, registry_url: str, app_id: str) -> object | None:
        pass
