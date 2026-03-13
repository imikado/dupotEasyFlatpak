from abc import abstractmethod

from domain.entity.recipe_entity import RecipeEntity


class RecipeRepositoryContract:

    @abstractmethod
    def has_id(self, id: str) -> bool:
        pass

    @abstractmethod
    def get_by_id(self, id: str) -> RecipeEntity:
        pass
