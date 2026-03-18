import json


class UserSettingsEntity:

    version: int = 16
    installation_scope: str = "user"
    installation_game_path: str = ""

    def __init__(self, raw_obj: object | None = None):

        if raw_obj != None:
            self.version = raw_obj["version"]
            self.installation_scope = raw_obj["installation_scope"]
            self.installation_game_path = raw_obj["installation_game_path"]

    def get_json_string(self) -> str:
        return json.dumps(self)
