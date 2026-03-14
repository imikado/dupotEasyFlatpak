from domain.contract.recipe_repository_contract import RecipeRepositoryContract
from domain.entity.permission_override_entity import PermissionOverrideEntity
from infrastructure.api.system_api import SystemApi


class GetRecipeContentUc:

    _recipe_repository: RecipeRepositoryContract

    def __init__(self, recipe_repository: RecipeRepositoryContract):
        self._recipe_repository = recipe_repository

        pass

    def has_recipe(self, id: str) -> bool:
        return self._recipe_repository.has_id(id)

    def is_hidden(self, id: str) -> bool:
        return self._recipe_repository.get_by_id(id).is_hidden()

    def get_permission_to_override_list_by_id(
        self, id: str
    ) -> list[PermissionOverrideEntity]:
        recipe = self._recipe_repository.get_by_id(id)

        return recipe.get_permission_to_override_list()
