from domain.UseCase.get_home_content_uc import GetHomeContentUC
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.repository.category_repository import CategoryRepository
from infrastructure.ui.appstream_page import AppstreamPage
from infrastructure.ui.category_list_page import CategoryListPage
from infrastructure.ui.search_list_page import SearchListPage
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

import subprocess
import threading

from gi.repository import GLib, Gio, Gtk, Adw


class MainWindow(Adw.ApplicationWindow):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.set_title("Easy flatpak")
        self.set_default_size(1000, 800)

        self._toast_overlay = Adw.ToastOverlay()
        self.set_content(self._toast_overlay)

        # Create navigation view for in-window navigation
        self.navigation_view = Adw.NavigationView()
        self._toast_overlay.set_child(self.navigation_view)

        # Create and push the home page
        home_page = self._create_home_page()
        self.navigation_view.push(home_page)

        # Handle close request to prompt for unsaved changes
        self.connect("close-request", self._on_close_request)

    def _create_home_page(self):
        page = Adw.NavigationPage.new(self._create_home_content(), _("Easy flatpak"))
        return page

    def _create_home_content(self):
        toolbar_view = Adw.ToolbarView()
        header_bar = Adw.HeaderBar()
        toolbar_view.add_top_bar(header_bar)

        menu = Gio.Menu()
        menu.append(_("Parameters"), "win.parameters")
        menu.append(_("Import / Export"), "win.import_export")
        menu.append(_("About"), "win.about")

        menu_button = Gtk.MenuButton()
        menu_button.set_icon_name("open-menu-symbolic")
        menu_button.set_menu_model(menu)
        header_bar.pack_end(menu_button)

        for name, callback in [
            ("parameters", self._on_menu_parameters),
            ("import_export", self._on_menu_import_export),
            ("about", self._on_menu_about),
        ]:
            action = Gio.SimpleAction.new(name, None)
            action.connect("activate", callback)
            self.add_action(action)

        css_provider = Gtk.CssProvider()
        css_provider.load_from_string(
            """
            .update-badge {
                background-color: @destructive_bg_color;
                color: @destructive_fg_color;
                border-radius: 999px;
                font-size: 0.7em;
                font-weight: bold;
                min-width: 16px;
                min-height: 16px;
                padding: 0px 2px;
            }
        """
        )
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        update_btn = Gtk.Button()
        update_btn.set_icon_name("software-update-available-symbolic")
        update_btn.set_tooltip_text(_("Available updates"))

        badge_label = Gtk.Label()
        badge_label.add_css_class("update-badge")
        badge_label.set_halign(Gtk.Align.END)
        badge_label.set_valign(Gtk.Align.START)
        badge_label.set_margin_end(-6)
        badge_label.set_margin_top(-4)
        badge_label.set_visible(False)

        overlay = Gtk.Overlay()
        overlay.set_child(update_btn)
        overlay.add_overlay(badge_label)
        overlay.set_visible(False)
        header_bar.pack_start(overlay)

        def _fetch_updates():
            result = subprocess.run(
                ["flatpak", "remote-ls", "--updates"],
                capture_output=True,
                text=True,
            )
            count = len([l for l in result.stdout.splitlines() if l.strip()])

            def _apply():
                if count > 0:
                    badge_label.set_label(str(count))
                    badge_label.set_visible(True)
                    overlay.set_visible(True)
                return GLib.SOURCE_REMOVE

            GLib.idle_add(_apply)

        threading.Thread(target=_fetch_updates, daemon=True).start()

        appstream_repository = AppstreamRepository()

        search_entry = Gtk.SearchEntry()
        search_entry.set_placeholder_text(_("Search…"))
        search_entry.set_hexpand(True)
        header_bar.set_title_widget(search_entry)
        search_entry.connect("search-changed", self._on_search, appstream_repository)

        get_home_content_uc = GetHomeContentUC(
            ApiCacheRepository(), appstream_repository, FlathubApi(), SystemApi()
        )

        stack = Gtk.Stack()
        stack.set_vexpand(True)
        stack.set_hexpand(True)
        stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)

        stack_switcher = Gtk.StackSwitcher()
        stack_switcher.set_stack(stack)
        stack_switcher.set_halign(Gtk.Align.CENTER)

        tabs = [
            (_("Trending"), get_home_content_uc.get_trending_appstream_list()),
            (_("Popular"), get_home_content_uc.get_popular_appstream_list()),
            (_("Updated"), get_home_content_uc.get_updated_appstream_list()),
        ]

        for title, app_list in tabs:
            scroll = Gtk.ScrolledWindow()
            scroll.set_vexpand(True)
            scroll.set_hexpand(True)
            scroll.set_child(
                self._get_application_list_widget(app_list, appstream_repository)
            )
            stack.add_titled(scroll, title.lower(), title)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.append(stack_switcher)
        box.append(stack)

        toolbar_view.set_content(box)
        toolbar_view.add_bottom_bar(self._create_category_bar(appstream_repository))

        return toolbar_view

    def _create_category_bar(self, appstream_repository: AppstreamRepository):
        category_icons = {
            "AudioVideo": "audio-x-generic-symbolic",
            "Development": "applications-development-symbolic",
            "Education": "applications-education-symbolic",
            "Game": "applications-games-symbolic",
            "Graphics": "applications-graphics-symbolic",
            "Network": "network-workgroup-symbolic",
            "Office": "applications-office-symbolic",
            "Science": "applications-science-symbolic",
            "System": "applications-system-symbolic",
            "Utility": "applications-utilities-symbolic",
        }

        flow = Gtk.FlowBox()
        flow.set_selection_mode(Gtk.SelectionMode.NONE)
        flow.set_max_children_per_line(10)
        flow.set_min_children_per_line(3)
        flow.set_homogeneous(True)
        flow.set_row_spacing(8)
        flow.set_column_spacing(8)
        flow.set_margin_top(25)
        flow.set_margin_bottom(25)

        for category in CategoryRepository().get_all():
            icon_name = category_icons.get(
                category, "application-x-executable-symbolic"
            )

            btn_content = Adw.ButtonContent()
            btn_content.set_label(_(category))
            btn_content.set_icon_name(icon_name)

            btn = Gtk.Button()
            btn.set_child(btn_content)
            btn.add_css_class("pill")
            btn.connect(
                "clicked", self._on_category_clicked, category, appstream_repository
            )
            flow.append(btn)

        return flow

    def _get_application_list_widget(self, application_list, appstream_repository):
        grid = AppListGridShared()
        for app in application_list:
            grid.append(app, self._on_app_clicked, appstream_repository)
        return grid.get_widget()

    def _on_menu_parameters(self, _action, _param):
        dialog = Adw.MessageDialog.new(self, _("Parameters"), _("Not yet implemented."))
        dialog.add_response("close", _("Close"))
        dialog.present()

    def _on_menu_import_export(self, _action, _param):
        dialog = Adw.MessageDialog.new(
            self, _("Import / Export"), _("Not yet implemented.")
        )
        dialog.add_response("close", _("Close"))
        dialog.present()

    def _on_menu_about(self, _action, _param):
        about = Adw.AboutDialog.new()
        about.set_application_name("Easy Flatpak")
        about.set_version("1.0")
        about.set_developer_name("dupot")
        about.set_license_type(Gtk.License.GPL_3_0)
        about.present(self)

    def _on_search(
        self, entry: Gtk.SearchEntry, appstream_repository: AppstreamRepository
    ):
        query = entry.get_text().strip()
        if len(query) > 2:
            if not isinstance(self.navigation_view.get_visible_page(), SearchListPage):
                self.navigation_view.push(SearchListPage(query, appstream_repository))

    def _on_category_clicked(
        self, _button, category: str, appstream_repository: AppstreamRepository
    ):
        self.navigation_view.push(CategoryListPage(category, appstream_repository))

    def _on_app_clicked(
        self, _button, app_id: str, appstream_repository: AppstreamRepository
    ):
        app = appstream_repository.get_by_id(app_id)
        if app:
            self.navigation_view.push(AppstreamPage(app))

    def _on_close_request(self, _window):

        return False  # Allow window to close


class AppWindow(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.dupot.easyflatpak")

    def do_activate(self):
        win = MainWindow(application=self)
        win.present()
