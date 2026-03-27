import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw

from domain.entity.user_settings_entity import UserSettingsEntity
from infrastructure.api.system_api import SystemApi
from infrastructure.api.user_settings_api import UserSettingsApi


class ParametersDialog(Adw.PreferencesDialog):

    def __init__(self):
        super().__init__()
        self.set_title(_("Parameters"))

        self._settings = UserSettingsEntity()
        self._user_settings_api = UserSettingsApi(SystemApi())

        page = Adw.PreferencesPage()
        self.add(page)

        group = Adw.PreferencesGroup()
        group.set_title(_("Installation"))
        page.add(group)

        self._scope_row = Adw.ComboRow()
        self._scope_row.set_title(_("Installation scope"))
        self._scope_row.set_subtitle(_("Where Flatpak apps will be installed"))
        scope_model = Gtk.StringList.new(["user", "system"])
        self._scope_row.set_model(scope_model)
        self._scope_row.set_selected(0 if self._settings.is_user_scope() else 1)
        self._scope_row.connect("notify::selected", lambda *_: self._on_change())
        group.add(self._scope_row)

        self._path_row = Adw.EntryRow()
        self._path_row.set_title(_("Game path"))
        self._path_row.set_text(self._settings.installation_game_path)
        self._path_row.connect("changed", lambda *_: self._on_change())
        group.add(self._path_row)

        save_group = Adw.PreferencesGroup()
        page.add(save_group)

        self._save_btn = Gtk.Button(label=_("Save"))
        self._save_btn.add_css_class("suggested-action")
        self._save_btn.add_css_class("pill")
        self._save_btn.set_halign(Gtk.Align.CENTER)
        self._save_btn.set_margin_top(8)
        self._save_btn.set_margin_bottom(8)
        self._save_btn.set_sensitive(False)
        self._save_btn.connect("clicked", self._on_save)
        save_group.add(self._save_btn)

    def _on_change(self):
        self._save_btn.set_sensitive(True)

    def _on_save(self, _btn):
        item = self._scope_row.get_selected_item()
        if item:
            self._settings.installation_scope = item.get_string()
        self._settings.installation_game_path = self._path_row.get_text()
        self._user_settings_api.save()
        self.close()
