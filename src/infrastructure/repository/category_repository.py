from domain.contract.category_repository_contract import CategoryRepositoryContract
from infrastructure.api.database_api import DatabaseApi


class CategoryRepository(CategoryRepositoryContract):

    def __init__(self):
        super().__init__()
        self._db = DatabaseApi()

    pass

    def get_all(self) -> list[str]:
        rows = self._db.execute("SELECT id FROM category")
        if len(rows):
            return [row["id"] for row in rows]
        return []
