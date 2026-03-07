import sqlite3
import os


class DatabaseApi:

    _DB_PATH = os.path.normpath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "..",
            "assets",
            "db",
            "flathub_database.db",
        )
    )
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._connection = sqlite3.connect(cls._DB_PATH)
            cls._instance._connection.row_factory = sqlite3.Row
        return cls._instance

    def __init__(self):
        pass

    def execute(self, query: str, params: tuple = ()) -> list:
        cursor = self._connection.cursor()
        cursor.execute(query, params)
        return cursor.fetchall()

    def close(self):
        self._connection.close()
