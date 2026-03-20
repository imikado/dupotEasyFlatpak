import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw

from domain.entity.flatpak_history_entity import FlatpakHistoryEntity


class DowngradeDialog(Adw.AlertDialog):

    def __init__(self, history_list: list[FlatpakHistoryEntity], on_confirm, current_commit: str | None = None):
        super().__init__()
        self.set_heading(_("Downgrade"))
        self.set_body(_("Select a version to downgrade to"))

        self._on_confirm = on_confirm
        self._selected_commit = None

        list_box = Gtk.ListBox()
        list_box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        list_box.add_css_class("boxed-list")

        current_row = None
        for entry in history_list:
            row = Adw.ActionRow()
            row.set_title(entry.subject)
            row.set_subtitle(entry.date)
            row._commit = entry.commit
            if current_commit and entry.commit.startswith(current_commit[:12]):
                row.set_title(f"{entry.subject} ✓")
                current_row = row
            list_box.append(row)

        if current_row is not None:
            list_box.select_row(current_row)
            self._selected_commit = current_row._commit
            self.set_response_enabled("confirm", True)

        list_box.connect("row-selected", self._on_row_selected)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_min_content_height(240)
        scroll.set_max_content_height(360)
        scroll.set_child(list_box)

        self.set_extra_child(scroll)
        self.add_response("cancel", _("Cancel"))
        self.add_response("confirm", _("Downgrade"))
        self.set_response_appearance("confirm", Adw.ResponseAppearance.DESTRUCTIVE)
        self.set_response_enabled("confirm", False)
        self.set_default_response("cancel")
        self.set_close_response("cancel")
        self.connect("response", self._on_response)

    def _on_row_selected(self, _list_box, row):
        has_selection = row is not None
        self.set_response_enabled("confirm", has_selection)
        if has_selection:
            self._selected_commit = row._commit

    def _on_response(self, _dialog, response):
        if response == "confirm" and self._selected_commit:
            self._on_confirm(self._selected_commit)
