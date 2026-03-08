from domain.conf.path_conf import PathConf


class AppstreamLongEntity:

    id: str
    name: str
    summary: str
    icon: str
    project_license: str
    category_id_list: str
    description: str
    metadata_obj: str
    url_obj: str
    release_obj_list: str
    last_update: int
    developer_name: str
    screenshot_list: str
    last_release_timestamp: int

    # maps entity field name -> DB column name
    _db_column_map = {
        "id": "id",
        "name": "name",
        "summary": "summary",
        "icon": "icon",
        "project_license": "projectLicense",
        "category_id_list": "categoryIdList",
        "description": "description",
        "metadata_obj": "metadataObj",
        "url_obj": "urlObj",
        "release_obj_list": "releaseObjList",
        "last_update": "lastUpdate",
        "developer_name": "developer_name",
        "screenshot_list": "screenshotList",
        "last_release_timestamp": "lastReleaseTimestamp",
    }

    def __init__(self, row={}):
        if row == {}:
            return
        for field in self._db_column_map:
            setattr(self, field, row[field])

    def get_select_columns(self) -> str:
        return ", ".join(
            f"{col} AS {field}" if col != field else col
            for field, col in self._db_column_map.items()
        )

    def getIcon(self) -> str:
        return PathConf().get_icons_path() + f"/{self.id.lower()}.png"
