from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.entity.appstream_long_entity import AppstreamLongEntity
from domain.entity.appstream_short_entity import AppstreamShortEntity
from infrastructure.api.database_api import DatabaseApi


class AppstreamRepository(AppstreamRepositoryContract):

    def __init__(self):
        super().__init__()
        self._db = DatabaseApi()

    def get_by_id(self, id: str) -> AppstreamLongEntity | None:
        rows = self._db.execute(
            f"SELECT {AppstreamLongEntity().get_select_columns()} FROM appstream WHERE id = ?",
            (id,),
        )
        if not rows:
            return None
        row = rows[0]
        return AppstreamLongEntity(row)

    def get_list_by_id_list(self, ids: list[str]) -> list[AppstreamShortEntity]:
        placeholders = ",".join("?" * len(ids))
        rows = self._db.execute(
            f"SELECT id, name, icon, summary FROM appstream WHERE id IN ({placeholders})",
            tuple(ids),
        )
        return [
            AppstreamShortEntity(row["id"], row["name"], row["icon"], row["summary"])
            for row in rows
        ]

    def get_list_by_category_id(self, category_id: str) -> list[AppstreamShortEntity]:
        rows = self._db.execute(
            f"SELECT id, name, icon, summary FROM appstream WHERE categoryIdList like '%{category_id}%'",
        )
        return [
            AppstreamShortEntity(row["id"], row["name"], row["icon"], row["summary"])
            for row in rows
        ]

    def get_list_by_category_id_and_search(
        self, category_id: str, search: str
    ) -> list[AppstreamShortEntity]:
        rows = self._db.execute(
            f"""SELECT id, name, icon, summary,
                CASE WHEN name LIKE '%{search}%' THEN 1 ELSE 2 END AS priority
                FROM appstream
                WHERE categoryIdList LIKE '%{category_id}%'
                AND (name LIKE '%{search}%' OR summary LIKE '%{search}%')
                ORDER BY priority""",
        )
        return [
            AppstreamShortEntity(row["id"], row["name"], row["icon"], row["summary"])
            for row in rows
        ]

    def get_list_by_seach(self, search: str) -> list[AppstreamShortEntity]:
        rows = self._db.execute(
            f"""SELECT id, name, icon, summary,
                CASE WHEN name LIKE '%{search}%' THEN 1 ELSE 2 END AS priority
                FROM appstream
                WHERE name LIKE '%{search}%' OR summary LIKE '%{search}%'
                ORDER BY priority""",
        )
        return [
            AppstreamShortEntity(row["id"], row["name"], row["icon"], row["summary"])
            for row in rows
        ]
