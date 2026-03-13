import os
import subprocess
import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared


def _flatpak_cmd(*args) -> list:
    prefix = ["flatpak-spawn", "--host"] if os.path.exists("/.flatpak-info") else []
    return prefix + ["flatpak"] + list(args)


class InstalledPage(Gtk.Box):

    def __init__(self, appstream_repository: AppstreamRepository, push_fn):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self._appstream_repository = appstream_repository
        self._push_fn = push_fn

        self._stack = Gtk.Stack()
        self._stack.set_vexpand(True)
        self._stack.set_hexpand(True)

        spinner = Gtk.Spinner()
        spinner.set_spinning(True)
        spinner.set_halign(Gtk.Align.CENTER)
        spinner.set_valign(Gtk.Align.CENTER)
        self._stack.add_named(spinner, "loading")

        empty_label = Gtk.Label(label=_("No installed applications found"))
        empty_label.add_css_class("dim-label")
        self._stack.add_named(empty_label, "empty")

        self._grid = AppListGridShared()
        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._grid.get_widget())
        self._stack.add_named(scroll, "list")

        self.append(self._stack)
        self._stack.set_visible_child_name("loading")

        threading.Thread(target=self._load, daemon=True).start()

    def _load(self):
        result = subprocess.run(
            _flatpak_cmd("list", "--app", "--columns=application"),
            capture_output=True,
            text=True,
        )
        ids = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        GLib.idle_add(self._apply, ids)

    def _apply(self, ids: list):
        if not ids:
            self._stack.set_visible_child_name("empty")
            return

        apps = self._appstream_repository.get_list_by_id_list(ids)
        if not apps:
            self._stack.set_visible_child_name("empty")
            return

        for app in apps:
            self._grid.append(app, self._on_app_clicked)

        self._stack.set_visible_child_name("list")
        return GLib.SOURCE_REMOVE

    def _on_app_clicked(self, _button, app_id: str):
        from infrastructure.ui.appstream_page import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self._push_fn(AppstreamPage(app))
