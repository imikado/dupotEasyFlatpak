import json


class UserSettingsEntity:

    INSTALLATION_USER_SCOPE = "user"

    _instance: "UserSettingsEntity | None" = None

    DEFAULT_VERSION = 16
    DEFAULT_INSTALLATION_SCOPE = INSTALLATION_USER_SCOPE
    DEFAULT_GAME_PATH = ""

    version: int = DEFAULT_VERSION
    installation_scope: str = DEFAULT_INSTALLATION_SCOPE
    installation_game_path: str = DEFAULT_GAME_PATH

    def __new__(cls, *_args, **_kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def load(self, raw_obj: object):
        self.version = raw_obj["version"]
        self.installation_scope = raw_obj["installation_scope"]
        self.installation_game_path = raw_obj["installation_game_path"]

    def is_user_scope(self) -> bool:
        if self.installation_scope == self.INSTALLATION_USER_SCOPE:
            return True
        return False

    def has_game_path(self) -> bool:
        return len(self.installation_game_path) > 0

    def get_json_string(self) -> str:
        return json.dumps(
            {
                "version": self.version,
                "installation_scope": self.installation_scope,
                "installation_game_path": self.installation_game_path,
            }
        )
