import os
import sys
from domain.UseCase.update_database_from_api_uc import UpdateDatabaseFromApiUc
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw

from domain.entity.user_settings_entity import UserSettingsEntity
from infrastructure.api.system_api import SystemApi
from infrastructure.api.user_settings_api import UserSettingsApi
from infrastructure.ui.shared.icons_shared import IconsShared


class ParametersDialog(Adw.PreferencesDialog):

    def __init__(self):
        super().__init__()
        self.set_title(_("Parameters"))

        self._settings = UserSettingsEntity()
        self._user_settings_api = UserSettingsApi(SystemApi())
        self._initial_language = self._settings.language

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

        arch_choices = self._settings.get_architecture_filter_choice_list()
        self._arch_row = Adw.ComboRow()
        self._arch_row.set_title(_("Architecture filter"))
        self._arch_row.set_subtitle(_("Filter apps by CPU architecture"))
        self._arch_row.set_model(Gtk.StringList.new(arch_choices))
        current_arch = self._settings.architecture_filter
        self._arch_row.set_selected(
            arch_choices.index(current_arch) if current_arch in arch_choices else 0
        )
        self._arch_row.connect("notify::selected", lambda *_: self._on_change())
        group.add(self._arch_row)

        # game path
        path_row = Adw.ActionRow(title=_("Game path"))

        self._path_row = Gtk.Entry()
        self._path_row.set_placeholder_text("/home/user/games...")
        self._path_row.set_valign(Gtk.Align.CENTER)
        self._path_row.set_hexpand(True)
        self._path_row.set_text(self._settings.installation_game_path)

        self._path_row.connect("changed", lambda *_: self._on_change())
        path_row.add_suffix(self._path_row)
        # end game path

        group.add(path_row)

        appearance_group = Adw.PreferencesGroup()
        appearance_group.set_title(_("Appearance"))
        page.add(appearance_group)

        theme_choices = self._settings.get_theme_choice_list()
        self._theme_row = Adw.ComboRow()
        self._theme_row.set_title(_("Theme"))
        self._theme_row.set_model(Gtk.StringList.new(theme_choices))
        current_theme = self._settings.theme
        selected_index = (
            theme_choices.index(current_theme) if current_theme in theme_choices else 0
        )
        self._theme_row.set_selected(selected_index)
        self._theme_row.connect("notify::selected", lambda *_: self._on_change())
        appearance_group.add(self._theme_row)

        language_choices = self._settings.get_language_choice_list()
        self._language_row = Adw.ComboRow()
        self._language_row.set_title(_("Language"))
        self._language_row.set_model(
            Gtk.StringList.new([_(c) for c in language_choices])
        )
        current_language = self._settings.language
        selected_lang_index = (
            language_choices.index(current_language)
            if current_language in language_choices
            else 0
        )
        self._language_row.set_selected(selected_lang_index)
        self._language_row.connect("notify::selected", lambda *_: self._on_change())
        appearance_group.add(self._language_row)

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
        arch_choices = self._settings.get_architecture_filter_choice_list()
        self._settings.architecture_filter = arch_choices[self._arch_row.get_selected()]
        theme_item = self._theme_row.get_selected_item()
        if theme_item:
            self._settings.theme = theme_item.get_string()
        language_choices = self._settings.get_language_choice_list()
        new_language = language_choices[self._language_row.get_selected()]
        language_changed = self._settings.language != new_language

        self._settings.language = new_language
        self._user_settings_api.save()

        if language_changed:
            self.detect_language_change()

        self._apply_theme()
        if self._settings.language != self._initial_language:
            self.close()
            os.execv(sys.executable, [sys.executable] + sys.argv)
        self.close()

    def detect_language_change(self):
        print('reload language')
        AppstreamRepository().reset_updated_for_all()
        ApiCacheRepository().reset_api_lastupdate()

        UpdateDatabaseFromApiUc(
            FlathubApi(), AppstreamRepository(), SystemApi(), ApiCacheRepository()
        ).process()

    def _apply_theme(self):
        style_manager = Adw.StyleManager.get_default()
        if self._settings.use_theme_dark():
            style_manager.set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        elif self._settings.use_theme_light():
            style_manager.set_color_scheme(Adw.ColorScheme.FORCE_LIGHT)
        else:
            style_manager.set_color_scheme(Adw.ColorScheme.DEFAULT)
