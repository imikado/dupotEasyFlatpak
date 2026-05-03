import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from domain.UseCase.get_search_content_uc import GetSearchContentUc
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared


class SearchListPage(Adw.NavigationPage):

    def __init__(self, query: str, appstream_repository: AppstreamRepository):
        super().__init__()
        self.set_title(_("Search"))
        self._appstream_repository = appstream_repository
        self._uc = GetSearchContentUc(appstream_repository, FlathubApi(), SystemApi())
        self._grid = None
        self._current_query = query
        self.set_child(self._build(query))

    def _build(self, query: str) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()

        header_bar = Adw.HeaderBar()
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        title_box.set_halign(Gtk.Align.CENTER)
        title_icon = Gtk.Image.new_from_icon_name("system-search-symbolic")
        title_label = Gtk.Label(label=_("Search"))
        title_label.add_css_class("heading")
        title_box.append(title_icon)
        title_box.append(title_label)
        header_bar.set_title_widget(title_box)
        toolbar_view.add_top_bar(header_bar)

        search_entry = Gtk.SearchEntry()
        search_entry.set_text(query)
        search_entry.set_hexpand(True)

        search_clamp = Adw.Clamp()
        search_clamp.set_maximum_size(700)
        search_clamp.set_margin_top(12)
        search_clamp.set_margin_bottom(12)
        search_clamp.set_margin_start(12)
        search_clamp.set_margin_end(12)
        search_clamp.set_child(search_entry)

        self._grid = AppListGridShared()

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._grid.get_widget())

        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        content_box.append(search_clamp)
        content_box.append(scroll)

        toolbar_view.set_content(content_box)

        search_entry.connect("search-changed", self._on_search_changed)

        def _focus_end(_page):
            search_entry.grab_focus()
            search_entry.set_position(-1)

        self.connect("shown", _focus_end)
        self._reload(query)

        return toolbar_view

    def _reload(self, query: str):
        self._current_query = query
        self._grid.clear()

        if len(query.strip()) < 3:
            return

        local_results = self._uc.get_app_list_by_search(query)
        for app in local_results:
            self._grid.append(app, self._on_row_activated)

        if not local_results:
            threading.Thread(
                target=self._search_api, args=(query,), daemon=True
            ).start()

    def _search_api(self, query: str):
        results = self._uc.get_app_list_from_api(query)
        GLib.idle_add(self._on_api_results, query, results)

    def _on_api_results(self, query: str, results: list):
        if query == self._current_query:
            for app in results:
                self._grid.append(app, self._on_row_activated)
        return GLib.SOURCE_REMOVE

    def _on_search_changed(self, entry: Gtk.SearchEntry):
        self._reload(entry.get_text())

    def _on_row_activated(self, _row, app_id: str):
        from infrastructure.ui.appstream_page import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
