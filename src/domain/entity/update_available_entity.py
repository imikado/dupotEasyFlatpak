class UpdateAvailableEntity:

    app_id: str
    name: str
    version: str
    current_version: str

    def __init__(self, app_id: str, name: str, version: str):
        self.app_id = app_id
        self.name = name
        self.version = version
        self.current_version = ""

    def set_current_version(self, version: str):
        self.current_version = version

    def has_current_version(self) -> bool:
        if len(self.current_version) > 0:
            return True
        return False

    def has_version(self) -> bool:
        if len(self.version) > 0:
            return True
        return False
