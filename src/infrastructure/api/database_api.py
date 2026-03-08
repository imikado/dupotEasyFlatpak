import sqlite3
import os

from domain.conf.path_conf import PathConf


class DatabaseApi:

    _instance = None

    def __new__(cls):
        if cls._instance is None:

            path_conf = PathConf()

            cls._instance = super().__new__(cls)
            cls._instance._connection = sqlite3.connect(path_conf.get_database_path())
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
