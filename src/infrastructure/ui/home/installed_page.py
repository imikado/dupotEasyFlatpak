import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib, Gio

from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.shared.installed_list_shared import InstalledListShared


class InstalledPage(Gtk.Box):

    def __init__(
        self,
        appstream_repository: AppstreamRepository,
        push_fn,
        on_import=None,
        on_export=None,
        on_open_flatpak=None,
    ):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self._appstream_repository = appstream_repository
        self._push_fn = push_fn
        self._flatpak_api = FlatpakApi()
        self._on_open_flatpak = on_open_flatpak

        self.append(self._build_toolbar(on_import, on_export))

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

        self._grid = InstalledListShared()
        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._grid.get_widget())
        self._stack.add_named(scroll, "list")

        self.append(self._stack)
        self._stack.set_visible_child_name("loading")

        threading.Thread(target=self._load, daemon=True).start()

    def _build_toolbar(self, on_import, on_export) -> Gtk.Box:
        toolbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        toolbar.set_margin_top(12)
        toolbar.set_margin_bottom(4)
        toolbar.set_margin_start(24)
        toolbar.set_margin_end(24)
        toolbar.set_halign(Gtk.Align.END)

        import_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        import_box.append(Gtk.Image.new_from_icon_name("document-open-symbolic"))
        import_box.append(Gtk.Label(label=_("Import")))
        import_btn = Gtk.Button()
        import_btn.set_child(import_box)
        import_btn.set_tooltip_text(_("Import"))
        if on_import:
            import_btn.connect("clicked", lambda _: on_import(None, None))
        toolbar.append(import_btn)

        export_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        export_box.append(Gtk.Image.new_from_icon_name("document-save-symbolic"))
        export_box.append(Gtk.Label(label=_("Export")))
        export_btn = Gtk.Button()
        export_btn.set_child(export_box)
        export_btn.set_tooltip_text(_("Export"))
        if on_export:
            export_btn.connect("clicked", lambda _: on_export(None, None))
        toolbar.append(export_btn)

        flatpak_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        flatpak_box.append(Gtk.Image.new_from_icon_name("package-x-generic-symbolic"))
        flatpak_box.append(Gtk.Label(label=_("Install local Flatpak")))
        flatpak_btn = Gtk.Button()
        flatpak_btn.set_child(flatpak_box)
        flatpak_btn.set_tooltip_text(_("Install local Flatpak"))
        flatpak_btn.connect("clicked", self._on_open_flatpak_clicked)
        toolbar.append(flatpak_btn)

        return toolbar

    def _on_open_flatpak_clicked(self, _btn):
        file_dialog = Gtk.FileDialog.new()
        file_dialog.set_title(_("Install local Flatpak"))
        filter_flatpak = Gtk.FileFilter()
        filter_flatpak.set_name(_("Flatpak files"))
        filter_flatpak.add_pattern("*.flatpak")
        filters = Gio.ListStore.new(Gtk.FileFilter)
        filters.append(filter_flatpak)
        file_dialog.set_filters(filters)
        file_dialog.open(self.get_root(), None, self._on_flatpak_file_chosen)

    def _on_flatpak_file_chosen(self, file_dialog, result):
        try:
            file = file_dialog.open_finish(result)
        except GLib.Error:
            return
        if self._on_open_flatpak:
            self._on_open_flatpak(file.get_path())

    def refresh(self):
        self._grid.clear()
        self._stack.set_visible_child_name("loading")
        threading.Thread(target=self._load, daemon=True).start()

    def _load(self):
        ids = self._flatpak_api.get_installed_app_id_list()
        GLib.idle_add(self._apply, ids)

    def _apply(self, ids: list):
        if not ids:
            self._stack.set_visible_child_name("empty")
            return

        apps = self._appstream_repository.get_list_by_id_list_ordered(ids)
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
