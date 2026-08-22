import json
import os

from domain.conf.path_conf import PathConf


class AppstreamShortEntity:

    FIELD_BRANDING = "branding"
    FIELD_BRANDING_LIGHT = "light"
    FIELD_BRANDING_DARK = "dark"

    _branding_loaded: bool = False
    _branding_light: str = "#888888"
    _branding_dark: str = "#333333"

    def __init__(self, id, name, icon, summary, metadata_obj="{}", flatpak_repo_id="flathub"):
        self.id = id
        self.name = name
        self.icon = icon
        self.summary = summary
        self.raw_metadata_obj = metadata_obj
        self.flatpak_repo_id = flatpak_repo_id

        pass

    def getName(self) -> str:
        return self.name

    def getSummary(self) -> str:
        return self.summary

    def getIcon(self) -> str:
        return PathConf().get_icons_path() + f"/{self.id.lower()}.png"

    def get_flatpak_repo_id(self) -> str:
        return self.flatpak_repo_id or "flathub"

    def _load_branding(self):

        if self._branding_loaded:
            return

        if not self.raw_metadata_obj or not isinstance(self.raw_metadata_obj, (str, bytes, bytearray)):
            self._branding_loaded = True
            return

        metadata_obj = json.loads(self.raw_metadata_obj)

        if self.FIELD_BRANDING in metadata_obj:
            branding = metadata_obj.get(self.FIELD_BRANDING)
            if self.FIELD_BRANDING_DARK in branding:
                self._branding_dark = branding.get(self.FIELD_BRANDING_DARK)
            if self.FIELD_BRANDING_LIGHT in branding:
                self._branding_light = branding.get(self.FIELD_BRANDING_LIGHT)
        self._branding_loaded = True

    def get_branding_light(self) -> str:
        self._load_branding()
        return self._branding_light

    def get_branding_dark(self) -> str:
        self._load_branding()
        return self._branding_dark

    pass
