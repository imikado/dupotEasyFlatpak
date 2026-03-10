import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, GLib, Gtk

from domain.UseCase.get_category_content_uc import GetCategoryContentUc
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared

BATCH_SIZE = 20


class CategoryListPage(Adw.NavigationPage):

    def __init__(self, category: str, appstream_repository: AppstreamRepository):
        super().__init__()
        self.set_title(_(category))
        self._appstream_repository = appstream_repository
        self._grid = None
        self._pending = []
        self._idle_id = None
        self.set_child(self._build(category))

    def _build(self, category: str) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        self._grid = AppListGridShared()

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._grid.get_widget())

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
            self._grid.append(app, self._on_app_clicked)

        return GLib.SOURCE_CONTINUE

    def _cancel_pending(self, _page):
        if self._idle_id is not None:
            GLib.source_remove(self._idle_id)
            self._idle_id = None
            self._pending = []

    def _on_app_clicked(self, _button, app_id: str):
        from infrastructure.ui.appstream_page import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
