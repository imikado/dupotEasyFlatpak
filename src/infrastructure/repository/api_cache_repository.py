import json

from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.entity.api_cache_entity import ApiCacheEntity
from infrastructure.api.database_api import DatabaseApi


class ApiCacheRepository(ApiCacheRepositoryContract):

    def __init__(self):
        super().__init__()
        self._db = DatabaseApi()

    def get_by_id(self, id: str) -> ApiCacheEntity | None:
        rows = self._db.execute("SELECT id,content FROM apicache WHERE id = ?", (id,))
        return ApiCacheEntity(rows[0]["id"], rows[0]["content"]) if rows else None

    def update_by_id(self, id: str, content_value: any) -> ApiCacheEntity | None:
        self._db.execute(
            "UPDATE apicache SET content = ? WHERE id = ?",
            (json.dumps(content_value), id),
        )

    def reset_api_lastupdate(self):
        self._db.execute(
            "UPDATE apicache SET content = ? WHERE id = ?",
            ('{"lastApiSyncTimeStamp": 0, "lastHomeApiSyncTimeStamp": 0}', 'parameters'))
        