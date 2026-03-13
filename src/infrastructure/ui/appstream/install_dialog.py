import subprocess
import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from domain.UseCase.get_recipe_content_uc import GetRecipeContentUc


class InstallDialog(Adw.AlertDialog):

    def __init__(
        self,
        app_id: str,
        has_recipe: bool,
        get_recipe_content: GetRecipeContentUc,
        on_confirm,  # callable(user_scope: bool, active_permissions: list)
    ):
        super().__init__()
        self.set_heading(_("Install"))

        self._on_confirm = on_confirm

        form_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        form_box.set_margin_top(8)

        self._permission_rows = []  # list of (widget, PermissionOverrideEntity)

        # Scope switch — always shown
        scope_group = Adw.PreferencesGroup()
        self._user_scope_row = Adw.SwitchRow()
        self._user_scope_row.set_title(_("Install for current user only"))
        scope_group.add(self._user_scope_row)
        form_box.append(scope_group)

        if has_recipe:
            permissions = get_recipe_content.get_permission_to_override_list_by_id(
                app_id
            )
            if permissions:
                perm_group = Adw.PreferencesGroup()
                perm_group.set_title(_("Permissions"))
                for perm in permissions:
                    if perm.is_filesystem_no_prompt():
                        continue
                    elif perm.is_filesystem():
                        row = Adw.EntryRow()
                        row.set_title(_(perm.get_label()))
                        row.set_text(perm.get_value())
                        perm_group.add(row)
                        self._permission_rows.append((row, perm))
                    elif perm.is_install_flatpak_yes_no():
                        row = Adw.SwitchRow()
                        row.set_title(_(perm.get_label()))
                        row.set_active(True)
                        perm_group.add(row)
                        self._permission_rows.append((row, perm))
                form_box.append(perm_group)

        self.set_extra_child(form_box)
        self.add_response("cancel", _("Cancel"))
        self.add_response("install", _("Install"))
        self.set_response_appearance("install", Adw.ResponseAppearance.SUGGESTED)
        self.set_default_response("install")
        self.set_close_response("cancel")

        self.connect("response", self._on_response)

    def _on_response(self, _dialog, response):
        if response != "install":
            return
        user_scope = (
            self._user_scope_row.get_active() if self._user_scope_row else False
        )
        active_permission_list = []
        for row, perm in self._permission_rows:
            if perm.is_filesystem():
                value = row.get_text().strip()
                if value:
                    active_permission_list.append((perm, value))
            elif perm.is_install_flatpak_yes_no():
                if row.get_active():
                    active_permission_list.append((perm, None))
        self._on_confirm(user_scope, active_permission_list)
