import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw

from domain.UseCase.get_search_content_uc import GetSearchContentUc
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared


class SearchListPage(Adw.NavigationPage):

    def __init__(self, query: str, appstream_repository: AppstreamRepository):
        super().__init__()
        self.set_title(_("Search"))
        self._appstream_repository = appstream_repository
        self._uc = GetSearchContentUc(appstream_repository)
        self._grid = None
        self.set_child(self._build(query))

    def _build(self, query: str) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()

        header_bar = Adw.HeaderBar()
        search_entry = Gtk.SearchEntry()
        search_entry.set_text(query)
        search_entry.set_hexpand(True)
        header_bar.set_title_widget(search_entry)
        toolbar_view.add_top_bar(header_bar)

        self._grid = AppListGridShared()

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._grid.get_widget())

        toolbar_view.set_content(scroll)

        search_entry.connect("search-changed", self._on_search_changed)

        def _focus_end(_page):
            search_entry.grab_focus()
            search_entry.set_position(-1)

        self.connect("shown", _focus_end)
        self._reload(query)

        return toolbar_view

    def _reload(self, query: str):
        self._grid.clear()

        if len(query.strip()) < 3:
            return

        for app in self._uc.get_app_list_by_search(query):
            self._grid.append(app, self._on_row_activated)

    def _on_search_changed(self, entry: Gtk.SearchEntry):
        self._reload(entry.get_text())

    def _on_row_activated(self, _row, app_id: str):
        from infrastructure.ui.appstream_page import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
