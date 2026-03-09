import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, GLib, Gtk

from domain.UseCase.get_category_content_uc import GetCategoryContentUc
from infrastructure.repository.appstream_repository import AppstreamRepository

BATCH_SIZE = 20


class CategoryListPage(Adw.NavigationPage):

    def __init__(self, category: str, appstream_repository: AppstreamRepository):
        super().__init__()
        self.set_title(_(category))
        self._appstream_repository = appstream_repository
        self._flow_box = None
        self._pending = []
        self._idle_id = None
        self.set_child(self._build(category))

    def _build(self, category: str) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        self._flow_box = Gtk.ListBox()
        self._flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self._flow_box.add_css_class("boxed-list")
        self._flow_box.set_margin_top(12)
        self._flow_box.set_margin_bottom(12)
        self._flow_box.set_margin_start(12)
        self._flow_box.set_margin_end(12)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._flow_box)

        toolbar_view.set_content(scroll)

        uc = GetCategoryContentUc(self._appstream_repository)
        self._pending = list(uc.get_app_list_by_category_id(category))
        self._idle_id = GLib.idle_add(self._append_batch)

        self.connect("hidden", self._cancel_pending)

        return toolbar_view

    def _append_batch(self) -> bool:
        if not self._pending:
            self._idle_id = None
            return GLib.SOURCE_REMOVE

        batch, self._pending = self._pending[:BATCH_SIZE], self._pending[BATCH_SIZE:]

        for app in batch:
            row = Adw.ActionRow()
            row.set_title(app.getName())
            row.set_subtitle(app.getSummary())
            row.set_activatable(True)

            icon = Gtk.Image.new_from_file(app.getIcon())
            icon.set_pixel_size(48)
            row.add_prefix(icon)

            row.add_suffix(Gtk.Image.new_from_icon_name("go-next-symbolic"))
            row.connect("activated", self._on_app_clicked, app.id)
            self._flow_box.append(row)

        return GLib.SOURCE_CONTINUE

    def _cancel_pending(self, _page):
        if self._idle_id is not None:
            GLib.source_remove(self._idle_id)
            self._idle_id = None
            self._pending = []

    def _on_app_clicked(self, _button, app_id: str):
        from infrastructure.ui.appstream_ui import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
