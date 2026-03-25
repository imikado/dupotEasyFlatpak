class ExportEntity:

    FIELD_APP_ID = "app_id"
    FIELD_INSTALL_SCOPE = "installation_scope"
    FIELD_OVERRIDE_FILESYSTEM = "override_filesystem_list"

    app_id: str
    installation_scope: str
    overrides_filesystem_list: list[str] = []

    def __init__(self, app_id: str, installation_scope: str):
        self.app_id = app_id
        self.installation_scope = installation_scope
        self.overrides_filesystem_list = []
        pass

    def add_override_filesystem(self, path: str):
        self.overrides_filesystem_list.append(path)

    def get_object(self) -> object:
        return {
            self.FIELD_APP_ID: self.app_id,
            self.FIELD_INSTALL_SCOPE: self.installation_scope,
            self.FIELD_OVERRIDE_FILESYSTEM: self.overrides_filesystem_list,
        }
