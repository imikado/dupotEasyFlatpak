from abc import ABC, abstractmethod

from domain.entity.flatpakrepo_entity import FlatpakRepoEntity


class FlatpakRepoRepositoryContract:

    @abstractmethod
    def get_all(self) -> list[str]:
        pass

    @abstractmethod
    def get_all_entities(self) -> list[FlatpakRepoEntity]:
        pass

    @abstractmethod
    def get_by_id(self, id: str) -> FlatpakRepoEntity | None:
        pass

    @abstractmethod
    def exists(self, id: str) -> bool:
        pass

    @abstractmethod
    def get_scope_flag(self, id: str, fallback: str) -> str:
        pass

    @abstractmethod
    def insert_repo_id(self, id: str,url:str, api:str, scope:str):
        pass