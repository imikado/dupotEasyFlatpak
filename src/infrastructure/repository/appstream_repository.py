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
            'SELECT * FROM appstream WHERE id = ?', (id,)
        )
        if not rows:
            return None
        row = rows[0]
        return AppstreamShortEntity(row['id'], row['name'], row['icon'], row['summary'])

    def get_by_id_list(self, ids: list[str]) -> list[AppstreamShortEntity]:
        placeholders = ','.join('?' * len(ids))
        rows = self._db.execute(
            f'SELECT id, name, icon, summary FROM appstream WHERE id IN ({placeholders})', tuple(ids)
        )
        return [AppstreamShortEntity(row['id'], row['name'], row['icon'], row['summary']) for row in rows]
