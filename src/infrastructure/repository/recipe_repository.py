from domain.conf.path_conf import PathConf
from domain.contract.recipe_repository_contract import RecipeRepositoryContract
from domain.entity.recipe_entity import RecipeEntity
from infrastructure.api.system_api import SystemApi


class RecipeRepository(RecipeRepositoryContract):

    _system_api: SystemApi

    _recipes_path: str

    def __init__(self):
        self._system_api = SystemApi()
        self._recipes_path = PathConf().get_asset_recipes_path()
        pass

    def _get_path_to_id(self, id: str) -> str:
        return PathConf().get_path_list_join([self._recipes_path, id + ".json"])

    def has_id(self, id: str) -> bool:
        return self._system_api.file_exists(self._get_path_to_id(id))

    def get_by_id(self, id: str) -> RecipeEntity:
        json_obj = self._system_api.read_json_file_obj(self._get_path_to_id(id))
        return RecipeEntity(json_obj)
