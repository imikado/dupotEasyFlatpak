from domain.entity.export_entity import ExportEntity


class ImportEntity:

    app_id: str
    name: str
    summary: str
    icon: str

    installation_scope: str
    overrides_filesystem_list: list[str]
    source_url: str
    found_in_catalog: bool

    def __init__(self, raw_obj: object):
        self.app_id = raw_obj[ExportEntity.FIELD_APP_ID]
        self.installation_scope = raw_obj[ExportEntity.FIELD_INSTALL_SCOPE]
        self.overrides_filesystem_list = raw_obj.get(
            ExportEntity.FIELD_OVERRIDE_FILESYSTEM, []
        )
        # Set only for apps with no repo of ours (installed from a GitHub
        # release) — reinstalled from there instead of a plain repo install.
        self.source_url = raw_obj.get(ExportEntity.FIELD_SOURCE_URL, "")
        # Set by ImportUc.get_appstream_list() when a matching row exists
        # in our appstream DB — i.e. it has a repo it can actually be
        # installed from.
        self.found_in_catalog = False

    def is_from_github(self) -> bool:
        return bool(self.source_url)

    def is_importable(self) -> bool:
        # No repo of ours and no GitHub source either — a plain
        # "flatpak install flathub <app_id>" would just fail for this one
        # (e.g. an older export, or a hand-edited import file).
        return self.found_in_catalog or self.is_from_github()

    def has_recipe_override_filesystem(self) -> bool:
        if len(self.overrides_filesystem_list) > 0:
            return True
        return False

    def get_recipe_overide_filesystem_list(self) -> list[str]:
        return self.overrides_filesystem_list
