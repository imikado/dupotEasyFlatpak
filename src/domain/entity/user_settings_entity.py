import json


class UserSettingsEntity:

    INSTALLATION_USER_SCOPE = "user"

    THEME_DARK = "dark"
    THEME_LIGHT = "light"
    THEME_SYSTEM = "system"

    FIELD_VERSION = "version"
    FIELD_INSTALLATION_SCOPE = "installation_scope"
    FIELD_INSTALLATION_GAME_PATH = "installation_game_path"
    FIELD_THEME = "theme"

    _instance: "UserSettingsEntity | None" = None

    DEFAULT_VERSION = 17
    DEFAULT_INSTALLATION_SCOPE = INSTALLATION_USER_SCOPE
    DEFAULT_GAME_PATH = ""
    DEFAULT_THEME = THEME_SYSTEM

    version: int = DEFAULT_VERSION
    installation_scope: str = DEFAULT_INSTALLATION_SCOPE
    installation_game_path: str = DEFAULT_GAME_PATH

    theme: str = DEFAULT_THEME

    def __new__(cls, *_args, **_kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def load(self, raw_obj: object):
        self.version = raw_obj[self.FIELD_VERSION]
        self.installation_scope = raw_obj[self.FIELD_INSTALLATION_SCOPE]
        self.installation_game_path = raw_obj[self.FIELD_INSTALLATION_GAME_PATH]

        if self.FIELD_THEME in raw_obj:
            self.theme = raw_obj[self.FIELD_THEME]

    def is_user_scope(self) -> bool:
        if self.installation_scope == self.INSTALLATION_USER_SCOPE:
            return True
        return False

    def has_game_path(self) -> bool:
        return len(self.installation_game_path) > 0

    def get_json_string(self) -> str:
        return json.dumps(
            {
                self.FIELD_VERSION: self.version,
                self.FIELD_INSTALLATION_SCOPE: self.installation_scope,
                self.FIELD_INSTALLATION_GAME_PATH: self.installation_game_path,
                self.FIELD_THEME: self.theme,
            }
        )

    def use_theme_system(self) -> bool:
        return self.theme == self.THEME_SYSTEM

    def use_theme_dark(self) -> bool:
        return self.theme == self.THEME_DARK

    def use_theme_light(self) -> bool:
        return self.theme == self.THEME_LIGHT

    def get_theme_choice_list(self) -> list[str]:
        return [self.THEME_DARK, self.THEME_LIGHT, self.THEME_SYSTEM]
