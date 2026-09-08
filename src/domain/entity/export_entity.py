class ExportEntity:

    FIELD_APP_ID = "app_id"
    FIELD_INSTALL_SCOPE = "installation_scope"
    FIELD_OVERRIDE_FILESYSTEM = "override_filesystem_list"
    FIELD_SOURCE_URL = "source_url"

    app_id: str
    installation_scope: str
    overrides_filesystem_list: list[str] = []
    source_url: str

    def __init__(self, app_id: str, installation_scope: str, source_url: str = ""):
        self.app_id = app_id
        self.installation_scope = installation_scope
        self.overrides_filesystem_list = []
        # Set only for apps installed from a GitHub release (no repo of
        # ours to reinstall from) — lets an import reinstall them from there.
        self.source_url = source_url
        pass

    def add_override_filesystem(self, path: str):
        self.overrides_filesystem_list.append(path)

    def get_object(self) -> object:
        obj = {
            self.FIELD_APP_ID: self.app_id,
            self.FIELD_INSTALL_SCOPE: self.installation_scope,
            self.FIELD_OVERRIDE_FILESYSTEM: self.overrides_filesystem_list,
        }
        if self.source_url:
            obj[self.FIELD_SOURCE_URL] = self.source_url
        return obj
