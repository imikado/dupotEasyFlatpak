from domain.contract.flatpakrepo_repository_contract import FlatpakRepoRepositoryContract
from domain.entity.flatpakrepo_entity import FlatpakRepoEntity
from infrastructure.api.database_api import DatabaseApi


class FlatpakRepoRepository(FlatpakRepoRepositoryContract):

    def __init__(self):
        super().__init__()
        self._db = DatabaseApi()

    pass

    def get_all(self) -> list[str]:
        rows = self._db.execute("SELECT id,url FROM flatpakRepo")
        if len(rows):
            return [row["id"] for row in rows]
        return []

    def get_by_id(self, id: str) -> FlatpakRepoEntity | None:
        rows = self._db.execute(
            "SELECT id,url,api FROM flatpakRepo WHERE id = ?",
            (id,),
        )
        if not rows:
            return None
        row = rows[0]
        return FlatpakRepoEntity(row)

    def get_all_entities(self) -> list[FlatpakRepoEntity]:
        rows = self._db.execute(
            "SELECT id,url,api FROM flatpakRepo WHERE id IS NOT NULL"
        )
        return [FlatpakRepoEntity(row) for row in rows]

    def exists(self, id: str) -> bool:
        return self.get_by_id(id) is not None

    def insert_repo_id(self, id: str,url:str, api:str):
            self._db.execute(
                """
                    INSERT INTO flatpakRepo 
                    (
                    id,
                    url,
                    api
                     ) values (?,?,?) """,
                (
                    id,
                    url,
                    api
                ),
            )
    