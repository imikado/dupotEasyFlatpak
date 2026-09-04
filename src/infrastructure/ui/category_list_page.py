import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, GLib, Gtk

from domain.UseCase.get_category_content_uc import GetCategoryContentUc
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared
from infrastructure.ui.shared.repo_filter_bar_shared import RepoFilterBar

BATCH_SIZE = 20


class CategoryListPage(Adw.NavigationPage):

    def __init__(
        self, category: str, cat_icon, appstream_repository: AppstreamRepository
    ):
        super().__init__()
        self.set_title(_(category))
        self._appstream_repository = appstream_repository
        self._category = category
        self._uc = GetCategoryContentUc(appstream_repository)
        self._grid = None
        self._pending = []
        self._idle_id = None
        self.set_child(self._build(category, cat_icon))

    def _build(self, category: str, cat_icon) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()

        header_bar = Adw.HeaderBar()

        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        title_box.set_halign(Gtk.Align.CENTER)
        title_icon = cat_icon
        title_icon.set_pixel_size(16)
        title_label = Gtk.Label(label=_(category))
        title_label.add_css_class("heading")
        title_box.append(title_icon)
        title_box.append(title_label)
        header_bar.set_title_widget(title_box)

        self._search_entry = Gtk.SearchEntry()
        self._search_entry.set_placeholder_text(_("Search…"))
        self._search_entry.set_hexpand(True)
        self._search_entry.connect("search-changed", self._on_search_changed)

        search_clamp = Adw.Clamp()
        search_clamp.set_maximum_size(500)
        search_clamp.set_child(self._search_entry)

        search_bar_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        search_bar_box.set_margin_top(4)
        search_bar_box.set_margin_bottom(4)
        search_bar_box.set_margin_start(8)
        search_bar_box.set_margin_end(8)
        search_bar_box.append(search_clamp)

        toolbar_view.add_top_bar(header_bar)
        toolbar_view.add_top_bar(search_bar_box)

        self._repo_filter = RepoFilterBar(on_change=self._on_repo_filter_changed)
        if self._repo_filter.widget:
            toolbar_view.add_top_bar(self._repo_filter.widget)

        self._grid = AppListGridShared()

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._grid.get_widget())

        toolbar_view.set_content(scroll)

        self._reload_apps(self._uc.get_app_list_by_category_id(category))

        self.connect("hidden", self._cancel_pending)

        return toolbar_view

    def _reload_apps(self, apps):
        self._cancel_pending(None)
        self._grid.clear()
        self._pending = list(apps)
        self._idle_id = GLib.idle_add(self._append_batch)

    def _append_batch(self) -> bool:
        if not self._pending:
            self._idle_id = None
            return GLib.SOURCE_REMOVE

        batch, self._pending = self._pending[:BATCH_SIZE], self._pending[BATCH_SIZE:]

        for app in batch:
            if self._repo_filter.matches(app):
                self._grid.append(app, self._on_app_clicked)

        return GLib.SOURCE_CONTINUE

    def _cancel_pending(self, _page):
        if self._idle_id is not None:
            GLib.source_remove(self._idle_id)
            self._idle_id = None
            self._pending = []

    def _get_apps_for_current_query(self):
        query = self._search_entry.get_text().strip()
        if len(query) >= 2:
            return self._uc.get_app_list_by_category_id_and_search(
                self._category, query
            )
        return self._uc.get_app_list_by_category_id(self._category)

    def _on_search_changed(self, _entry: Gtk.SearchEntry):
        self._reload_apps(self._get_apps_for_current_query())

    def _on_repo_filter_changed(self, _repo_id):
        self._reload_apps(self._get_apps_for_current_query())

    def _on_app_clicked(self, _button, app_id: str):
        from infrastructure.ui.appstream_page import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
