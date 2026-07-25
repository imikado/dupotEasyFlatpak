import json


class UserSettingsEntity:

    INSTALLATION_USER_SCOPE = "user"

    THEME_DARK = "dark"
    THEME_LIGHT = "light"
    THEME_SYSTEM = "system"

    LANGUAGE_SYSTEM = "system"
    LANGUAGE_FR = "french"
    LANGUAGE_EN = "english"
    LANGUAGE_AR = "arabic"
    LANGUAGE_ES = "spanish"
    LANGUAGE_IT = "italian"
    LANGUAGE_PT = "portugues"
    LANGUAGE_RO = "romanian"

    LANGUAGE_EN_CODE="en"

    ARCHITECTURE_FILTER_X86="x86_64"
    ARCHITECTURE_FILTER_ARM="aarch64"
    ARCHITECTURE_FILTER_NONE="none" 

    FIELD_VERSION = "version"
    FIELD_INSTALLATION_SCOPE = "installation_scope"
    FIELD_INSTALLATION_GAME_PATH = "installation_game_path"
    FIELD_THEME = "theme"
    FIELD_LANGUAGE = "language"
    FIELD_ARCHITECTURE_FILTER="architecture_filter"

    _instance: "UserSettingsEntity | None" = None

    DEFAULT_VERSION = 18
    DEFAULT_INSTALLATION_SCOPE = INSTALLATION_USER_SCOPE
    DEFAULT_GAME_PATH = ""
    DEFAULT_THEME = THEME_SYSTEM
    DEFAULT_LANGUAGE = LANGUAGE_SYSTEM
    DEFAULT_ARCHITECTURE_FILTER= ARCHITECTURE_FILTER_NONE

    version: int = DEFAULT_VERSION
    installation_scope: str = DEFAULT_INSTALLATION_SCOPE
    installation_game_path: str = DEFAULT_GAME_PATH

    theme: str = DEFAULT_THEME
    language: str = DEFAULT_LANGUAGE
    architecture_filter:str=DEFAULT_ARCHITECTURE_FILTER

    def __new__(cls, *_args, **_kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def reset_to_defaults(self) -> None:
        self.version = self.DEFAULT_VERSION
        self.installation_scope = self.DEFAULT_INSTALLATION_SCOPE
        self.installation_game_path = self.DEFAULT_GAME_PATH
        self.theme = self.DEFAULT_THEME
        self.language = self.DEFAULT_LANGUAGE
        self.architecture_filter= self.DEFAULT_ARCHITECTURE_FILTER

    def load(self, raw_obj: object):
        self.version = raw_obj[self.FIELD_VERSION]
        self.installation_scope = raw_obj[self.FIELD_INSTALLATION_SCOPE]
        self.installation_game_path = raw_obj[self.FIELD_INSTALLATION_GAME_PATH]

        if self.FIELD_THEME in raw_obj:
            self.theme = raw_obj[self.FIELD_THEME]

        if self.FIELD_LANGUAGE in raw_obj:
            self.language = raw_obj[self.FIELD_LANGUAGE]

        if self.FIELD_ARCHITECTURE_FILTER in raw_obj:
            self.architecture_filter = raw_obj[self.FIELD_ARCHITECTURE_FILTER]

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
                self.FIELD_LANGUAGE: self.language,
                self.FIELD_ARCHITECTURE_FILTER:self.architecture_filter
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

    def get_language_choice_list(self) -> list[str]:
        return [
            self.LANGUAGE_SYSTEM,
            self.LANGUAGE_AR,
            self.LANGUAGE_EN,
            self.LANGUAGE_ES,
            self.LANGUAGE_FR,
            self.LANGUAGE_IT,
            self.LANGUAGE_PT,
            self.LANGUAGE_RO,
        ]

    def should_force_language(self) -> bool:
        return self.language != self.LANGUAGE_SYSTEM

    def get_language_code(self) -> str:
        language_codes = {
            self.LANGUAGE_AR: "ar",
            self.LANGUAGE_EN: self.LANGUAGE_EN_CODE,
            self.LANGUAGE_ES: "es",
            self.LANGUAGE_FR: "fr",
            self.LANGUAGE_IT: "it",
            self.LANGUAGE_PT: "pt_BR",
            self.LANGUAGE_RO: "ro",
        }
        return language_codes.get(self.language, "en")

    def get_architecture_filter_choice_list(self) -> list[str]:
        return [
            self.ARCHITECTURE_FILTER_ARM,
            self.ARCHITECTURE_FILTER_X86,
            self.ARCHITECTURE_FILTER_NONE
        ]
    
    def set_architecture_filter(self,architecture_filter:str):
        self.architecture_filter=architecture_filter

    def get_architecture_filter_arch(self) -> str | None:
        if self.architecture_filter == self.ARCHITECTURE_FILTER_X86:
            return self.ARCHITECTURE_FILTER_X86
        if self.architecture_filter == self.ARCHITECTURE_FILTER_ARM:
            return self.ARCHITECTURE_FILTER_ARM
        return None

    