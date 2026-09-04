import gi

gi.require_version("Gtk", "4.0")

from gi.repository import Gtk

from infrastructure.repository.flatpakrepo_repository import FlatpakRepoRepository

_css_provider = Gtk.CssProvider()
_css_provider.load_from_string(
    ".repo-filter-chip { padding: 1px 8px; min-height: 0; }"
)


class RepoFilterBar:
    """Segmented "All" / <repo id> filter — only builds a widget when the
    user actually has more than one repo configured, since with just
    Flathub there's nothing to filter between."""

    def __init__(self, on_change):
        self._on_change = on_change
        self._selected_repo_id = None
        self.widget = None

        repo_id_list = [
            entity.getId() for entity in FlatpakRepoRepository().get_all_entities()
        ]
        if len(repo_id_list) <= 1:
            return

        if "flathub" in repo_id_list:
            repo_id_list.remove("flathub")
            repo_id_list.insert(0, "flathub")

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        row.set_halign(Gtk.Align.CENTER)
        row.set_margin_top(2)
        row.set_margin_bottom(4)
        row.connect(
            "realize",
            lambda w: Gtk.StyleContext.add_provider_for_display(
                w.get_display(), _css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
            ),
        )

        def on_toggled(btn, repo_id):
            if btn.get_active():
                self._selected_repo_id = repo_id
                self._on_change(repo_id)

        all_btn = Gtk.ToggleButton(label=_("All"))
        all_btn.add_css_class("repo-filter-chip")
        all_btn.set_active(True)
        all_btn.connect("toggled", on_toggled, None)
        row.append(all_btn)

        for repo_id in repo_id_list:
            btn = Gtk.ToggleButton(label=repo_id)
            btn.add_css_class("repo-filter-chip")
            # set_group makes these behave like radio buttons: exactly one
            # stays active, and clicking the active one is a no-op instead
            # of leaving nothing selected.
            btn.set_group(all_btn)
            btn.connect("toggled", on_toggled, repo_id)
            row.append(btn)

        self.widget = row

    def matches(self, app) -> bool:
        if self._selected_repo_id is None:
            return True
        return self._selected_repo_id in app.get_flatpak_repo_id_list()
