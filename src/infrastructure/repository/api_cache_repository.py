import json

from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.entity.api_cache_entity import ApiCacheEntity
from infrastructure.api.database_api import DatabaseApi


class ApiCacheRepository(ApiCacheRepositoryContract):

    def __init__(self):
        super().__init__()
        self._db=DatabaseApi()


    def get_by_id(self, id: str) -> ApiCacheEntity | None:
        rows = self._db.execute('SELECT id,content FROM apicache WHERE id = ?', (id,))
        return ApiCacheEntity(rows[0]['id'],rows[0]['content']) if rows else None

    def update_by_id(self, id: str,app_id_list:list[str]) -> ApiCacheEntity | None:
        self._db.execute('UPDATE apicache SET content = ? WHERE id = ?', (json.dumps(app_id_list),id))
