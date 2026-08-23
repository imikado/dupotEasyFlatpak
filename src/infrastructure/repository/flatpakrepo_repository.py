from domain.contract.flatpakrepo_repository_contract import FlatpakRepoRepositoryContract
from domain.entity.flatpakrepo_entity import FlatpakRepoEntity
from infrastructure.api.database_api import DatabaseApi


class FlatpakRepoRepository(FlatpakRepoRepositoryContract):

    def __init__(self):
        super().__init__()
        self._db = DatabaseApi()

    pass

    def get_all(self) -> list[str]:
        rows = self._db.execute("SELECT id,url,scope FROM flatpakRepo")
        if len(rows):
            return [row["id"] for row in rows]
        return []

    def get_by_id(self, id: str) -> FlatpakRepoEntity | None:
        rows = self._db.execute(
            "SELECT id,url,api,scope FROM flatpakRepo WHERE id = ?",
            (id,),
        )
        if not rows:
            return None
        row = rows[0]
        return FlatpakRepoEntity(row)

    def get_scope_flag(self, id: str, fallback: str) -> str:
        # Repos added through this app are pinned to whichever scope
        # (--user/--system) they were registered under — installing an app
        # from a different scope would fail since the remote isn't visible
        # there. "flathub"/"all"-scoped repos are exempt: they're
        # available in both, so the caller's own scope choice applies.
        entity = self.get_by_id(id)
        if entity and entity.getScope() and entity.getScope() != "all":
            return entity.getScope()
        return fallback

    def get_all_entities(self) -> list[FlatpakRepoEntity]:
        rows = self._db.execute(
            "SELECT id,url,api,scope FROM flatpakRepo WHERE id IS NOT NULL"
        )
        return [FlatpakRepoEntity(row) for row in rows]

    def exists(self, id: str) -> bool:
        return self.get_by_id(id) is not None

    def insert_repo_id(self, id: str,url:str, api:str,scope:str):
            # OR REPLACE: re-syncing an already-tracked repo (e.g. from
            # AddNewRemoteRepoUc.sync() on every launch) must update it in
            # place rather than crash with a UNIQUE constraint failure.
            self._db.execute(
                """
                    INSERT OR REPLACE INTO flatpakRepo
                    (
                    id,
                    url,
                    api,
                    scope
                     ) values (?,?,?,?) """,
                (
                    id,
                    url,
                    api,
                    scope
                ),
            )
    