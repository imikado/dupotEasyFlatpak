import json
import os
import subprocess
import threading

from domain.entity.user_settings_entity import UserSettingsEntity
import gi
from infrastructure.ui.shared.icons_shared import IconsShared

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib, Gdk

from domain.UseCase.get_recipe_content_uc import GetRecipeContentUc
from domain.conf.path_conf import PathConf
from domain.entity.bundle_entity import BundleEntity
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.repository.recipe_repository import RecipeRepository


class BundleDetailPage(Adw.NavigationPage):

    def __init__(self, bundle: BundleEntity, appstream_repository: AppstreamRepository):
        super().__init__()
        self.set_title(bundle.label)
        self._bundle = bundle
        self._appstream_repository = appstream_repository
        self._get_recipe = GetRecipeContentUc(RecipeRepository())
        self._flatpak_api = FlatpakApi()
        self._edit_mode = False
        self._app_rows = []  # list of (app_id, row, switch, remove_btn)
        self._app_permissions: dict[str, list] = {}  # app_id -> [(perm, value_or_None)]
        self._installed_ids: set[str] = set()
        self._apps_requiring_config: set[str] = set()
        self._listbox = None
        self._install_btn = None
        self._edit_btn = None
        self._user_scope_row = None
        self.set_child(self._build())
        threading.Thread(target=self._load_installed, daemon=True).start()

        self.user_settings_entity = UserSettingsEntity()

    def _build(self) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()

        header_bar = Adw.HeaderBar()
        header_bar.set_title_widget(Gtk.Label(label=self._bundle.label))

        self._edit_btn = Gtk.Button()
        self._edit_btn.set_icon_name(
            IconsShared().find_icon_name_available(IconsShared.ICON_EDIT)
        )
        self._edit_btn.set_tooltip_text(_("Edit bundle"))
        self._edit_btn.connect("clicked", self._on_edit_clicked)
        header_bar.pack_end(self._edit_btn)

        toolbar_view.add_top_bar(header_bar)

        self._listbox = Gtk.ListBox()
        self._listbox.add_css_class("boxed-list")
        self._listbox.set_selection_mode(Gtk.SelectionMode.NONE)

        self._populate_list()

        # Scope — identical layout to InstallDialog
        scope_group = Adw.PreferencesGroup()
        scope_group.set_margin_top(24)
        self._user_scope_row = Adw.SwitchRow()
        self._user_scope_row.set_title(_("Install for current user only"))
        self._user_scope_row.set_active(True)
        scope_group.add(self._user_scope_row)

        self._install_btn = Gtk.Button(label=_("Install selected"))
        self._install_btn.add_css_class("suggested-action")
        self._install_btn.add_css_class("pill")
        self._install_btn.set_halign(Gtk.Align.CENTER)
        self._install_btn.set_margin_top(16)
        self._install_btn.set_margin_bottom(24)
        self._install_btn.connect("clicked", self._on_install_clicked)

        inner_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        inner_box.set_margin_top(24)
        inner_box.set_margin_start(24)
        inner_box.set_margin_end(24)
        inner_box.append(self._listbox)
        inner_box.append(scope_group)
        inner_box.append(self._install_btn)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(800)
        clamp.set_child(inner_box)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(clamp)

        toolbar_view.set_content(scroll)
        return toolbar_view

    def _update_install_btn(self, *_args):
        if self._install_btn is None:
            return
        blocked = any(
            app_id in self._apps_requiring_config
            and app_id not in self._app_permissions
            and switch.get_active()
            for app_id, switch, _perm_btn in self._app_rows
        )
        self._install_btn.set_sensitive(not blocked)

    def _populate_list(self):
        while child := self._listbox.get_first_child():
            self._listbox.remove(child)
        self._app_rows = []
        self._apps_requiring_config = set()

        apps = self._appstream_repository.get_list_by_id_list(
            self._bundle.get_application_list()
        )

        for app in apps:
            row = Adw.ActionRow()
            row.set_title(app.getName())
            row.set_subtitle(app.getSummary())
            row.set_activatable(not self._edit_mode)

            icon = Gtk.Image.new_from_file(app.getIcon())
            icon.set_pixel_size(48)
            row.add_prefix(icon)

            perm_btn = None
            if (
                not self._edit_mode
                and self._get_recipe.has_recipe(app.id)
                and not self._get_recipe.is_hidden(app.id)
            ):
                self._apps_requiring_config.add(app.id)
                perm_btn = Gtk.Button()
                perm_btn.set_icon_name(
                    IconsShared().find_icon_name_available(IconsShared.ICON_EDITRECIPE)
                )
                perm_btn.add_css_class("flat")
                perm_btn.set_valign(Gtk.Align.CENTER)
                perm_btn.set_tooltip_text(_("Edit permissions"))
                if app.id not in self._app_permissions:
                    perm_btn.add_css_class("error")
                perm_btn.connect("clicked", self._on_perm_clicked, app.id, perm_btn)
                row.add_suffix(perm_btn)

            switch = Gtk.Switch()
            switch.set_active(True)
            switch.set_valign(Gtk.Align.CENTER)
            switch.set_visible(not self._edit_mode)
            switch.connect("notify::active", self._update_install_btn)
            row.add_suffix(switch)

            if not self._edit_mode:
                row.connect("activated", self._on_row_activated, app.id)

            self._listbox.append(row)
            self._app_rows.append((app.id, switch, perm_btn))

        self._update_install_btn()

    def _load_installed(self):
        ids = self._flatpak_api.get_installed_app_id_list()
        GLib.idle_add(self._apply_installed, ids)

    def _apply_installed(self, ids: list):
        self._installed_ids = set(ids)
        for app_id, switch, perm_btn in self._app_rows:
            if app_id in self._installed_ids:
                if perm_btn is not None:
                    perm_btn.set_sensitive(False)

                switch.set_active(False)
                switch.set_sensitive(False)

                switch.set_tooltip_text(_("Already installed"))

    def _on_edit_clicked(self, _btn):
        self._edit_mode = not self._edit_mode
        self._edit_btn.set_icon_name(
            IconsShared().find_icon_name_available(IconsShared.ICON_CHECKMARK)
            if self._edit_mode
            else IconsShared().find_icon_name_available(IconsShared.ICON_EDIT)
        )
        self._edit_btn.set_tooltip_text(
            _("Done") if self._edit_mode else _("Edit bundle")
        )
        self._populate_list()

    def _on_remove_app(self, _btn, app_id: str):
        app_list = self._bundle.get_application_list()
        if app_id in app_list:
            app_list.remove(app_id)
        self._save_bundle()
        self._populate_list()

    def _save_bundle(self):
        path = PathConf().get_asset_bundles_path()
        system_api = SystemApi()
        raw_list = system_api.read_json_file_obj_list(path)
        for raw in raw_list:
            if raw.get(BundleEntity.FIELD_ID) == self._bundle.id:
                raw[BundleEntity.FIELD_APP_LIST] = self._bundle.get_application_list()
                break
        system_api.write_file(path, json.dumps(raw_list, indent=4))

    def _on_perm_clicked(self, _btn, app_id: str, perm_btn: Gtk.Button):
        permissions = self._get_recipe.get_permission_to_override_list_by_id(app_id)
        visible_perms = [p for p in permissions if not p.is_filesystem_no_prompt()]
        if not visible_perms:
            return

        stored = {p.get_label(): v for p, v in self._app_permissions.get(app_id, [])}

        dialog = Adw.AlertDialog()
        dialog.set_heading(_("Permissions"))

        perm_group = Adw.PreferencesGroup()
        permission_rows = []

        for perm in visible_perms:
            if perm.is_filesystem():
                row = Adw.EntryRow()
                row.set_title(_(perm.get_label()))
                row.set_text(stored.get(perm.get_label()) or perm.get_value())

                if self.user_settings_entity.has_game_path():
                    row.set_text(self.user_settings_entity.installation_game_path)

                perm_group.add(row)
                permission_rows.append((row, perm))

            elif perm.is_filesystem_no_prompt():
                row = Adw.EntryRow()
                row.set_title(_(perm.get_label()))
                row.set_text(stored.get(perm.get_label()) or perm.get_value())
                perm_group.add(row)
                permission_rows.append((row, perm))

            elif perm.is_install_flatpak_yes_no():
                row = Adw.SwitchRow()
                row.set_title(_(perm.get_label()))
                row.set_active(perm.get_label() in stored if stored else True)
                if perm.get_value() in self._installed_ids:
                    info_icon = IconsShared().get_icon_by_name(IconsShared.ICON_INFO)
                    info_icon.set_tooltip_text(_("Already installed"))
                    info_icon.set_valign(Gtk.Align.CENTER)
                    row.add_suffix(info_icon)
                perm_group.add(row)
                permission_rows.append((row, perm))

        filesystem_entry_rows = [
            row
            for row, perm in permission_rows
            if perm.is_filesystem() or perm.is_filesystem_no_prompt()
        ]

        def _validate(*_args):
            ok = True
            dialog.set_response_enabled("ok", ok)

        for entry_row in filesystem_entry_rows:
            entry_row.connect("notify::text", _validate)

        dialog.set_extra_child(perm_group)
        dialog.add_response("cancel", _("Cancel"))
        dialog.add_response("ok", _("OK"))
        dialog.set_response_appearance("ok", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("ok")
        dialog.set_close_response("cancel")

        _validate()

        def on_response(_d, response):
            if response != "ok":
                return
            active_list = []
            for row, perm in permission_rows:
                if perm.is_filesystem():
                    value = row.get_text().strip()
                    if value:
                        active_list.append((perm, value))
                elif perm.is_install_flatpak_yes_no():
                    if row.get_active():
                        active_list.append((perm, None))
            self._app_permissions[app_id] = active_list
            perm_btn.remove_css_class("error")
            self._update_install_btn()

        dialog.connect("response", on_response)
        dialog.present(self)

    def _on_install_clicked(self, _btn):
        selected_ids = [
            app_id
            for app_id, switch, _perm_btn in self._app_rows
            if switch.get_active()
        ]
        if not selected_ids:
            return
        from infrastructure.service.install_queue_service import InstallQueueService

        user_scope = self._user_scope_row.get_active()
        scope = "user" if user_scope else "system"
        flags = ["--user"] if user_scope else ["--system"]
        queue = InstallQueueService()

        for app_id in selected_ids:
            app = self._appstream_repository.get_by_id(app_id)
            if not app:
                continue
            queue_item = queue.enqueue(app_id, app.getName(), scope)
            if self._get_recipe.has_recipe(app_id) and self._get_recipe.is_hidden(
                app_id
            ):
                active_permissions = [
                    (p, p.get_value())
                    for p in self._get_recipe.get_permission_to_override_list_by_id(
                        app_id
                    )
                ]
            else:
                active_permissions = self._app_permissions.get(app_id, [])

            def run_install(item=queue_item, aid=app_id, perms=active_permissions):
                def _stream(cmd):
                    process = subprocess.Popen(
                        cmd,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        text=True,
                    )
                    for line in process.stdout:
                        GLib.idle_add(item.append_output, line)
                    process.wait()

                flatpak_api = FlatpakApi()

                _stream(flatpak_api.get_install_call(aid, *flags))
                for perm, value in perms:
                    if perm.is_filesystem():
                        _stream(flatpak_api.get_override_filesystem_call(aid, value))
                    elif perm.is_install_flatpak_yes_no():
                        _stream(flatpak_api.get_install_call(perm.get_value(), *flags))
                result = FlatpakApi().get_info_by_id(aid)
                GLib.idle_add(
                    item.set_status, "done" if result.returncode == 0 else "failed"
                )

            threading.Thread(target=run_install, daemon=True).start()

    def _on_row_activated(self, _row, app_id: str):
        from infrastructure.ui.appstream_page import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
