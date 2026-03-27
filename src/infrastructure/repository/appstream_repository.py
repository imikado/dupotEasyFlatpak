import json

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

    def get_all_app_id_lastupdate_list(self) -> list[object]:
        rows = self._db.execute(
            f"SELECT id,lastUpdate FROM appstream  ",
        )
        return rows

    def get_list_by_id_list(self, ids: list[str]) -> list[AppstreamShortEntity]:
        placeholders = ",".join("?" * len(ids))
        rows = self._db.execute(
            f"SELECT id, name, icon, summary,metadataObj FROM appstream WHERE id IN ({placeholders})",
            tuple(ids),
        )
        return [
            AppstreamShortEntity(
                row["id"],
                row["name"],
                row["icon"],
                row["summary"],
                row["metadataObj"],
            )
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

    def get_summary_list_by_category_id(
        self, category_id: str
    ) -> list[AppstreamShortEntity]:
        rows = self._db.execute(
            f"SELECT id, name, icon, summary FROM appstream WHERE categoryIdList like '%{category_id}%' LIMIT 10",
        )
        return [
            AppstreamShortEntity(row["id"], row["name"], row["icon"], row["summary"])
            for row in rows
        ]

    def insert_from_raw_object(self, raw_obj: object):

        id = raw_obj["app_id"]
        name = raw_obj["name"]
        summary = raw_obj["summary"]
        project_license = raw_obj["project_license"]
        icon = raw_obj["icon"]
        category_id_list = [raw_obj["main_categories"]]
        developer_name = raw_obj["developer_name"]

        metadata_obj = {"verification_verified": raw_obj["verification_verified"]}

        self._db.execute(
            """
                INSERT INTO appstream 
                (
                id,
                name,
                summary,
                icon,
                projectLicense,
                categoryIdList,
                description,
                metadataObj,
                releaseObjList,
                lastUpdate,
                developer_name,
                screenshotList,
                lastReleaseTimestamp) values (?,?,?,?,?,?,?,?,?,?,?,?,?) """,
            (
                id,
                name,
                summary,
                icon,
                project_license,
                json.dumps(category_id_list),
                "",
                json.dumps(metadata_obj),
                "[]",
                0,
                developer_name,
                "[]",
                0,
            ),
        )

    def update_from_raw_object_with_id(self, id: str, raw_obj: object):
        import time

        name = raw_obj.get("name", "")
        summary = raw_obj.get("summary", "")
        description = raw_obj.get("description", "")
        project_license = raw_obj.get("project_license", "")
        developer_name = raw_obj.get("developer_name", "")
        icon = raw_obj.get("icon", "")

        categories = raw_obj.get("main_categories", raw_obj.get("categories", []))
        if isinstance(categories, str):
            categories = [categories]

        metadata_obj = {}
        raw_metadata = raw_obj.get("metadata", {}) or {}
        if raw_metadata.get("flathub::verification::verified"):
            metadata_obj["flathub_verified"] = True
            label = (
                raw_metadata.get("flathub::verification::website")
                or raw_metadata.get("flathub::verification::login_name")
                or ""
            )
            metadata_obj["flathub_verified_label"] = label
        for key in ["download_size", "installed_size"]:
            if key in raw_obj:
                metadata_obj[key] = raw_obj[key]

        branding = {}

        if "branding" in raw_obj:
            raw_branding_list = raw_obj.get("branding")

            if isinstance(raw_branding_list, list):

                for raw_branding_loop in raw_branding_list:
                    if not "scheme_preference" in raw_branding_loop:
                        continue
                    elif raw_branding_loop["scheme_preference"] == "light":
                        branding["light"] = raw_branding_loop["value"]
                    else:
                        branding["dark"] = raw_branding_loop["value"]

        metadata_obj["branding"] = branding

        screenshots = []
        raw_screenshot_list = raw_obj.get("screenshots")
        if isinstance(raw_screenshot_list, list):
            for raw_screenshot in raw_screenshot_list:
                if "sizes" in raw_screenshot:
                    screenshot = {}
                    for raw_size in raw_screenshot["sizes"]:
                        if int(raw_size["width"]) < 600:
                            screenshot["preview"] = raw_size["src"]
                        if int(raw_size["width"]) > 700:
                            screenshot["large"] = raw_size["src"]
                    if "preview" in screenshot and "large" in screenshot:
                        screenshots.append(screenshot)

        releases = raw_obj.get("releases", [])
        last_update = int(time.time() * 1000)

        self._db.execute(
            """UPDATE appstream SET
                name = ?,
                summary = ?,
                description = ?,
                projectLicense = ?,
                developer_name = ?,
                icon = ?,
                categoryIdList = ?,
                metadataObj = ?,
                screenshotList = ?,
                releaseObjList = ?,
                lastUpdate = ?
            WHERE id = ?""",
            (
                name,
                summary,
                description,
                project_license,
                developer_name,
                icon,
                json.dumps(categories),
                json.dumps(metadata_obj),
                json.dumps(screenshots),
                json.dumps(releases),
                last_update,
                id,
            ),
        )
