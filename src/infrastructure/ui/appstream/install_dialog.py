import subprocess
import threading

from domain.entity.user_settings_entity import UserSettingsEntity
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from domain.UseCase.get_recipe_content_uc import GetRecipeContentUc
from infrastructure.repository.flatpakrepo_repository import FlatpakRepoRepository
from infrastructure.ui.shared.icons_shared import IconsShared


class InstallDialog(Adw.AlertDialog):

    def __init__(
        self,
        app_id: str,
        has_recipe: bool,
        get_recipe_content: GetRecipeContentUc,
        on_confirm,  # callable(user_scope: bool, active_permissions: list, repo_id: str | None)
        heading: str = None,
        confirm_label: str = None,
        show_scope: bool = True,
        filesystem_override_values: list = None,
        locked_scope: str = None,  # "--user"/"--system" when the app's repo pins it, else None
        repo_id_list: list = None,  # flatpak remote ids this app is available from — the literal ids flatpak uses, e.g. "flathub"
    ):
        super().__init__()
        self.set_heading(heading or _("Install"))

        self._on_confirm = on_confirm
        # A picker is only worth showing when the app is actually available
        # from more than one repo — otherwise just use the single one given.
        self._repo_id_list = repo_id_list if repo_id_list and len(repo_id_list) > 1 else []
        # Same "flathub wins" default as AppstreamLongEntity.get_flatpak_repo_id().
        all_repo_ids = repo_id_list or []
        self._single_repo_id = (
            "flathub" if "flathub" in all_repo_ids
            else (all_repo_ids[0] if all_repo_ids else None)
        )
        self._repo_row = None

        form_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        form_box.set_margin_top(8)
        form_box.set_size_request(600, -1)

        self._permission_rows = []  # list of (widget, PermissionOverrideEntity)

        user_settings_entity = UserSettingsEntity()

        if self._repo_id_list:
            repo_group = Adw.PreferencesGroup()
            self._repo_row = Adw.ComboRow()
            self._repo_row.set_title(_("Repository"))
            self._repo_row.set_subtitle(_("This app is available from several repositories"))
            self._repo_row.set_model(Gtk.StringList.new(self._repo_id_list))
            preferred_index = (
                self._repo_id_list.index(self._single_repo_id)
                if self._single_repo_id in self._repo_id_list
                else 0
            )
            self._repo_row.set_selected(preferred_index)
            repo_group.add(self._repo_row)
            form_box.append(repo_group)

        # Scope switch — shown only when installing
        if show_scope:
            scope_group = Adw.PreferencesGroup()
            self._user_scope_row = Adw.SwitchRow()
            self._user_scope_row.set_title(_("Install for current user only"))
            scope_group.add(self._user_scope_row)
            form_box.append(scope_group)

            self._user_settings_entity = user_settings_entity
            self._apply_scope_lock(locked_scope)

            if self._repo_row:
                self._repo_row.connect("notify::selected", self._on_repo_selected)
        else:
            self._user_scope_row = None

        if has_recipe:
            permissions = get_recipe_content.get_permission_to_override_list_by_id(
                app_id
            )
            if permissions:
                perm_group = Adw.PreferencesGroup()
                perm_group.set_title(_("Permissions"))
                _fs_index = 0
                for perm in permissions:
                    if perm.is_filesystem_no_prompt():
                        continue
                    elif perm.is_filesystem():
                        path_row = Adw.ActionRow(title=_(perm.get_label()))

                        row = Gtk.Entry()
                        row.set_valign(Gtk.Align.CENTER)
                        row.set_hexpand(True)

                        path_row.add_suffix(row)

                        if user_settings_entity.has_game_path():
                            row.set_text(user_settings_entity.installation_game_path)
                        elif filesystem_override_values and _fs_index < len(
                            filesystem_override_values
                        ):
                            row.set_text(filesystem_override_values[_fs_index])
                        else:
                            row.set_text(perm.get_value())
                        _fs_index += 1
                        perm_group.add(path_row)
                        self._permission_rows.append((row, perm))
                    elif perm.is_install_flatpak_yes_no():
                        row = Adw.SwitchRow()
                        row.set_title(_(perm.get_label()))
                        row.set_active(True)
                        install_icon = IconsShared().get_icon_by_name(
                            IconsShared.ICON_PENDING
                        )
                        install_icon.set_valign(Gtk.Align.CENTER)
                        row.add_prefix(install_icon)
                        perm_group.add(row)
                        self._permission_rows.append((row, perm))
                form_box.append(perm_group)

        confirm_key = "confirm"
        self.set_extra_child(form_box)
        self.add_response("cancel", _("Cancel"))
        self.add_response(confirm_key, confirm_label or _("Install"))
        self.set_response_appearance(confirm_key, Adw.ResponseAppearance.SUGGESTED)
        self.set_default_response(confirm_key)
        self.set_close_response("cancel")

        self.connect("response", self._on_response)

    def _get_selected_repo_id(self) -> str:
        if self._repo_row:
            return self._repo_id_list[self._repo_row.get_selected()]
        return self._single_repo_id

    def _apply_scope_lock(self, locked_scope: str):
        if locked_scope:
            # This app's repo was only registered for one scope
            # (--user/--system) — installing at the other scope would
            # fail since the remote isn't visible there, so the choice
            # isn't left up to the user.
            self._user_scope_row.set_active(locked_scope == "--user")
            self._user_scope_row.set_sensitive(False)
            self._user_scope_row.set_subtitle(
                _("This repository only supports this scope")
            )
        else:
            self._user_scope_row.set_active(self._user_settings_entity.is_user_scope())
            self._user_scope_row.set_sensitive(True)
            self._user_scope_row.set_subtitle("")

    def _on_repo_selected(self, _row, _pspec):
        # Each repo can pin its own scope, so switching the repo can change
        # whether the user still gets to choose --user vs --system.
        locked_scope = FlatpakRepoRepository().get_scope_flag(
            self._get_selected_repo_id(), None
        )
        self._apply_scope_lock(locked_scope)

    def _on_response(self, _dialog, response):
        if response != "confirm":
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
        self._on_confirm(user_scope, active_permission_list, self._get_selected_repo_id())
