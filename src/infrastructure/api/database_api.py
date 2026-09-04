import json
import sqlite3
import os

from domain.conf.path_conf import PathConf


class DatabaseApi:

    _instance = None

    def __new__(cls):
        if cls._instance is None:

            path_conf = PathConf()

            cls._instance = super().__new__(cls)
            cls._instance._connection = sqlite3.connect(path_conf.get_database_path(), check_same_thread=False)
            cls._instance._connection.row_factory = sqlite3.Row
            cls._instance._migrate_schema()
        return cls._instance

    def __init__(self):
        pass

    def _migrate_schema(self):
        # The shipped asset DB is only re-copied on a version bump (see
        # main.py), so an already-installed user keeps their old sqlite
        # file across code updates — bring its schema up to date in place
        # instead of crashing with "no such column".
        cursor = self._connection.cursor()
        cursor.execute("PRAGMA table_info(appstream)")
        columns = {row["name"] for row in cursor.fetchall()}
        if not columns:
            return

        changed = False

        if "flatpakRepoIdList" not in columns:
            cursor.execute(
                "ALTER TABLE appstream ADD COLUMN flatpakRepoIdList TEXT DEFAULT '[]'"
            )
            changed = True
            if "flatpakRepoId" in columns:
                cursor.execute("SELECT id, flatpakRepoId FROM appstream")
                cursor.executemany(
                    "UPDATE appstream SET flatpakRepoIdList = ? WHERE id = ?",
                    [
                        (
                            json.dumps([row["flatpakRepoId"]] if row["flatpakRepoId"] else ["flathub"]),
                            row["id"],
                        )
                        for row in cursor.fetchall()
                    ],
                )

        # Older builds could have written a bare repo-id string into
        # flatpakRepoIdList instead of a JSON array — normalize those.
        cursor.execute(
            "SELECT id, flatpakRepoIdList FROM appstream"
            " WHERE flatpakRepoIdList IS NOT NULL AND flatpakRepoIdList NOT LIKE '[%'"
        )
        stale_rows = cursor.fetchall()
        if stale_rows:
            cursor.executemany(
                "UPDATE appstream SET flatpakRepoIdList = ? WHERE id = ?",
                [(json.dumps([row["flatpakRepoIdList"]]), row["id"]) for row in stale_rows],
            )
            changed = True

        cursor.execute(
            "INSERT OR IGNORE INTO apicache (id, content) VALUES ('ociMisses', '{}')"
        )
        if cursor.rowcount:
            changed = True

        if changed:
            self._connection.commit()

    def execute(self, query: str, params: tuple = ()) -> list:
        cursor = self._connection.cursor()
        cursor.execute(query, params)
        self._connection.commit()
        return cursor.fetchall()

    def close(self):
        self._connection.close()
