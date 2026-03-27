import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, GLib, Gtk

from domain.UseCase.get_category_content_uc import GetCategoryContentUc
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared

BATCH_SIZE = 20


class CategoryListPage(Adw.NavigationPage):

    def __init__(self, category: str, icon_name: str, appstream_repository: AppstreamRepository):
        super().__init__()
        self.set_title(_(category))
        self._appstream_repository = appstream_repository
        self._category = category
        self._uc = GetCategoryContentUc(appstream_repository)
        self._grid = None
        self._pending = []
        self._idle_id = None
        self.set_child(self._build(category, icon_name))

    def _build(self, category: str, icon_name: str) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()

        header_bar = Adw.HeaderBar()

        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        title_box.set_halign(Gtk.Align.CENTER)
        title_icon = Gtk.Image.new_from_icon_name(icon_name)
        title_icon.set_pixel_size(16)
        title_label = Gtk.Label(label=_(category))
        title_label.add_css_class("heading")
        title_box.append(title_icon)
        title_box.append(title_label)
        header_bar.set_title_widget(title_box)

        search_entry = Gtk.SearchEntry()
        search_entry.set_placeholder_text(_("Search…"))
        search_entry.set_hexpand(True)
        search_entry.connect("search-changed", self._on_search_changed)

        search_clamp = Adw.Clamp()
        search_clamp.set_maximum_size(500)
        search_clamp.set_child(search_entry)

        search_bar_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        search_bar_box.set_margin_top(4)
        search_bar_box.set_margin_bottom(4)
        search_bar_box.set_margin_start(8)
        search_bar_box.set_margin_end(8)
        search_bar_box.append(search_clamp)

        toolbar_view.add_top_bar(header_bar)
        toolbar_view.add_top_bar(search_bar_box)

        self._grid = AppListGridShared()

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._grid.get_widget())

        toolbar_view.set_content(scroll)

        self._pending = list(self._uc.get_app_list_by_category_id(category))
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

    def _on_search_changed(self, entry: Gtk.SearchEntry):
        query = entry.get_text().strip()
        self._cancel_pending(None)
        self._grid.clear()
        if len(query) >= 2:
            apps = self._uc.get_app_list_by_category_id_and_search(self._category, query)
        else:
            apps = self._uc.get_app_list_by_category_id(self._category)
        self._pending = list(apps)
        self._idle_id = GLib.idle_add(self._append_batch)

    def _on_app_clicked(self, _button, app_id: str):
        from infrastructure.ui.appstream_page import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
