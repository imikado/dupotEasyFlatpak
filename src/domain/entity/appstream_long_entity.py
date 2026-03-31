import json

from domain.conf.path_conf import PathConf
from domain.entity.release_entity import ReleaseEntity
from domain.entity.screenshot_entity import ScreenshotEntity


class AppstreamLongEntity:

    LAST_UPDATE_MAX_DAYS = 7

    FIELD_FLATHUB_VERIFIED = "flathub_verified"
    FIELD_FLATHUB_VERIFIED_LABEL = "flathub_verified_label"
    FIELD_DOWNLOAD_SIZE = "download_size"
    FIELD_INSTALLED_SIZE = "installed_size"

    FIELD_BRANDING = "branding"
    FIELD_BRANDING_LIGHT = "light"
    FIELD_BRANDING_DARK = "darkt"

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

    _screenshot_obj_list: list[ScreenshotEntity]
    _flathub_verified: bool
    _flathub_verified_label: str
    _download_size: int
    _installed_size: int
    _release_obj_list: list[ReleaseEntity]

    _branding_light: str = "eeeeee"
    _branding_dark: str = "cccccc"

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

        self.load_screenshot_list()
        self.load_metadata_obj()
        self.load_release_obj_list()

    def get_select_columns(self) -> str:
        return ", ".join(
            f"{col} AS {field}" if col != field else col
            for field, col in self._db_column_map.items()
        )

    def getName(self) -> str:
        return self.name

    def getIcon(self) -> str:
        return PathConf().get_icons_path() + f"/{self.id.lower()}.png"

    def load_screenshot_list(self):
        raw_list = json.loads(self.screenshot_list)
        screenshot_obj_list = []
        for raw_obj in raw_list:
            screenshot_obj_list.append(
                ScreenshotEntity(raw_obj["preview"], raw_obj["large"])
            )
        self._screenshot_obj_list = screenshot_obj_list

    def load_metadata_obj(self):
        raw_obj = json.loads(self.metadata_obj)
        self._flathub_verified = False
        self._flathub_verified_label = ""
        self._download_size = 0
        self._installed_size = 0

        if self.FIELD_FLATHUB_VERIFIED_LABEL in raw_obj:
            self._flathub_verified_label = raw_obj[self.FIELD_FLATHUB_VERIFIED_LABEL]
            self._flathub_verified = True

        if self.FIELD_DOWNLOAD_SIZE in raw_obj:
            self._download_size = raw_obj[self.FIELD_DOWNLOAD_SIZE]

        if self.FIELD_INSTALLED_SIZE in raw_obj:
            self._installed_size = raw_obj[self.FIELD_INSTALLED_SIZE]

        if self.FIELD_BRANDING in raw_obj:
            branding = raw_obj[self.FIELD_BRANDING]
            if self.FIELD_BRANDING_DARK in branding:
                self._branding_dark = branding[self.FIELD_BRANDING_DARK]
            if self.FIELD_BRANDING_LIGHT in branding:
                self._branding_dark = branding[self.FIELD_BRANDING_LIGHT]

    def load_release_obj_list(self):
        raw_obj_list = json.loads(self.release_obj_list)
        self._release_obj_list = []
        for raw_obj_loop in raw_obj_list:
            self._release_obj_list.append(
                ReleaseEntity(raw_obj_loop["timestamp"], raw_obj_loop["version"])
            )

    def get_download_size(self) -> str:
        return self.format_mb(self._download_size)

    def get_installed_size(self) -> str:
        return self.format_mb(self._installed_size)

    def is_flathub_verified(self) -> bool:
        return self._flathub_verified

    def get_flathub_verified_label(self) -> str:
        return self._flathub_verified_label

    def get_screenshot_list(self) -> list[ScreenshotEntity]:
        return self._screenshot_obj_list

    def get_release_list(self) -> list[ReleaseEntity]:
        return self._release_obj_list

    @staticmethod
    def format_mb(size: int) -> str:
        value = size / 1000000
        return f"{value:.1f} MB"

    def should_update(self, current_timestamp) -> bool:
        if (
            self.last_update + self.LAST_UPDATE_MAX_DAYS * 60 * 60 * 24
        ) < current_timestamp:
            return True
        return False

    def get_branding_light(self) -> str:
        return self._branding_light

    def get_branding_dark(self) -> str:
        return self._branding_dark
