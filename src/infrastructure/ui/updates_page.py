import os
import subprocess
import threading

from domain.UseCase.get_update_list_uc import GetUpdateListUc
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from domain.conf.path_conf import PathConf
from domain.entity.update_available_entity import UpdateAvailableEntity
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.service.install_queue_service import InstallQueueService


class UpdatesPage(Gtk.Box):

    def __init__(self, on_loaded=None):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self._flatpak_api = FlatpakApi()
        self._get_update_list_uc = GetUpdateListUc(self._flatpak_api)
        self._on_loaded = on_loaded
        self._checkboxes = []  # list of (UpdateAvailableEntity, Gtk.CheckButton)
        self._rows = []  # list of (Adw.ActionRow, bool) — bool = has_version

        self._stack = Gtk.Stack()
        self._stack.set_vexpand(True)
        self._stack.set_hexpand(True)

        spinner = Gtk.Spinner()
        spinner.set_spinning(True)
        spinner.set_halign(Gtk.Align.CENTER)
        spinner.set_valign(Gtk.Align.CENTER)
        self._stack.add_named(spinner, "loading")

        empty_label = Gtk.Label(label=_("No updates available"))
        empty_label.add_css_class("dim-label")
        self._stack.add_named(empty_label, "empty")

        self._group_with_version = Adw.PreferencesGroup()
        self._group_with_version.set_title(_("Applications"))

        self._group_without_version = Adw.PreferencesGroup()
        self._group_without_version.set_title(_("Runtimes"))

        groups_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        groups_box.set_margin_top(12)
        groups_box.set_margin_bottom(12)
        groups_box.set_margin_start(12)
        groups_box.set_margin_end(12)
        groups_box.append(self._group_with_version)
        groups_box.append(self._group_without_version)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(700)
        clamp.set_child(groups_box)

        list_scroll = Gtk.ScrolledWindow()
        list_scroll.set_vexpand(True)
        list_scroll.set_hexpand(True)
        list_scroll.set_child(clamp)
        self._stack.add_named(list_scroll, "list")

        self.append(self._stack)

        # --- Action bar (shown when at least one item is selected) ---
        self._action_bar = Gtk.ActionBar()

        self._select_all_btn = Gtk.Button(label=_("Select all"))
        self._select_all_btn.connect("clicked", self._on_select_all_clicked)
        self._action_bar.pack_start(self._select_all_btn)

        self._update_btn = Gtk.Button()
        self._update_btn.add_css_class("suggested-action")
        self._update_btn.connect("clicked", self._on_update_clicked)
        self._action_bar.pack_end(self._update_btn)
        self._action_bar.set_revealed(False)
        self.append(self._action_bar)

        self._stack.set_visible_child_name("loading")
        threading.Thread(target=self._load, daemon=True).start()

    def _load(self):
        items = self._get_update_list_uc.get_list()
        GLib.idle_add(self._apply, items)

    def _apply(self, items: list[UpdateAvailableEntity]):
        if not items:
            self._stack.set_visible_child_name("empty")
            if self._on_loaded:
                self._on_loaded(0)
            return GLib.SOURCE_REMOVE

        path_conf = PathConf()
        no_image = path_conf.get_asset_path() + "/images/no-image.png"

        for item in items:
            icon_path = path_conf.get_icons_path() + f"/{item.app_id.lower()}.png"
            icon = Gtk.Image.new_from_file(
                icon_path if os.path.exists(icon_path) else no_image
            )
            icon.set_pixel_size(48)
            icon.set_valign(Gtk.Align.CENTER)

            check = Gtk.CheckButton()
            check.set_valign(Gtk.Align.CENTER)
            check.connect("toggled", self._on_check_toggled)

            row = Adw.ActionRow()
            row.set_title(item.name)
            if item.has_current_version():
                row.set_subtitle(item.current_version + " → " + item.version)
            else:
                row.set_subtitle(item.version)
            row.add_prefix(icon)
            row.add_suffix(check)
            row.set_activatable_widget(check)

            self._checkboxes.append((item, check))

            if item.has_version():
                self._group_with_version.add(row)
                self._rows.append((row, True))
            else:
                self._group_without_version.add(row)
                self._rows.append((row, False))

        self._stack.set_visible_child_name("list")
        self._action_bar.set_revealed(True)
        self._update_btn.set_label(_("Update (0)"))
        if self._on_loaded:
            self._on_loaded(len(items))
        return GLib.SOURCE_REMOVE

    def _on_select_all_clicked(self, _btn):
        for _item, check in self._checkboxes:
            check.set_active(True)

    def _on_check_toggled(self, _check):
        selected = [item for item, check in self._checkboxes if check.get_active()]
        count = len(selected)
        self._action_bar.set_revealed(count > 0)
        self._update_btn.set_label(_("Update ({n})").format(n=count))

    def _on_update_clicked(self, _btn):
        selected = [item for item, check in self._checkboxes if check.get_active()]
        if not selected:
            return

        names = "\n".join(f"• {item.name}" for item in selected)
        dialog = Adw.AlertDialog.new(
            _("Update {n} application(s)?").format(n=len(selected)),
            names,
        )
        dialog.add_response("cancel", _("Cancel"))
        dialog.add_response("confirm", _("Update"))
        dialog.set_response_appearance("confirm", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("confirm")
        dialog.set_close_response("cancel")
        dialog.connect("response", self._on_confirm_response, selected)
        dialog.present(self.get_root())

    def refresh(self):
        for row, has_version in self._rows:
            if has_version:
                self._group_with_version.remove(row)
            else:
                self._group_without_version.remove(row)
        self._rows.clear()
        self._checkboxes.clear()
        self._action_bar.set_revealed(False)
        self._stack.set_visible_child_name("loading")
        threading.Thread(target=self._load, daemon=True).start()

    def _on_confirm_response(self, _dialog, response, selected):
        if response != "confirm":
            return

        queue_service = InstallQueueService()
        flatpak_api = self._flatpak_api
        pending = {"count": len(selected)}

        for item in selected:
            queue_item = queue_service.enqueue(item.app_id, item.name)

            def _run(qi=queue_item, app_id=item.app_id):
                process = subprocess.Popen(
                    flatpak_api.get_update_call(app_id),
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                )
                for line in process.stdout:
                    GLib.idle_add(qi.append_output, line)
                process.wait()
                final_status = "done" if process.returncode == 0 else "failed"
                GLib.idle_add(qi.set_status, final_status)
                pending["count"] -= 1
                if pending["count"] == 0:
                    GLib.idle_add(self.refresh)

            threading.Thread(target=_run, daemon=True).start()
