class InstalledVersionEntity:

    app_id: str
    version: str

    def __init__(self, app_id: str, version: str):
        self.app_id = app_id
        self.version = version
        pass
