from domain.entity.export_entity import ExportEntity


class ImportEntity:

    app_id: str
    name: str
    summary: str
    icon: str

    installation_scope: str
    overrides_filesystem_list: list[str]
    source_url: str

    def __init__(self, raw_obj: object):
        self.app_id = raw_obj[ExportEntity.FIELD_APP_ID]
        self.installation_scope = raw_obj[ExportEntity.FIELD_INSTALL_SCOPE]
        self.overrides_filesystem_list = raw_obj.get(
            ExportEntity.FIELD_OVERRIDE_FILESYSTEM, []
        )
        # Set only for apps with no repo of ours (installed from a GitHub
        # release) — reinstalled from there instead of a plain repo install.
        self.source_url = raw_obj.get(ExportEntity.FIELD_SOURCE_URL, "")

    def is_from_github(self) -> bool:
        return bool(self.source_url)

    def has_recipe_override_filesystem(self) -> bool:
        if len(self.overrides_filesystem_list) > 0:
            return True
        return False

    def get_recipe_overide_filesystem_list(self) -> list[str]:
        return self.overrides_filesystem_list
