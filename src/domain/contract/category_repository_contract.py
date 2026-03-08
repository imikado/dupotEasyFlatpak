from abc import ABC, abstractmethod


class CategoryRepositoryContract:

    @abstractmethod
    def get_all(self) -> list[str]:
        pass
