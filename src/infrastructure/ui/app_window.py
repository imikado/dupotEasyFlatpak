from domain.UseCase.get_home_content_uc import GetHomeContentUC
from domain.UseCase.get_bundle_content_uc import GetBundleContentUc
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.repository.bundle_repository import BundleRepository
from infrastructure.repository.category_repository import CategoryRepository
from infrastructure.ui.appstream_page import AppstreamPage
from infrastructure.ui.bundle_detail_page import BundleDetailPage
from infrastructure.ui.category_list_page import CategoryListPage
from infrastructure.service.install_queue_service import InstallQueueService
from infrastructure.ui.installed_page import InstalledPage
from infrastructure.ui.pending_list_page import PendingPage
from infrastructure.ui.search_list_page import SearchListPage
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

import os
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

        pending_badge_css = Gtk.CssProvider()
        pending_badge_css.load_from_string(
            """
            indicatorbin > label.badge,
            indicatorbin label.badge,
            viewswitcherbutton label.badge,
            viewswitcher label.badge {
                background-color: #8b0000;
                color: white;
                border-radius: 9999px;
            }
        """
        )
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            pending_badge_css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
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

        update_overlay = Gtk.Overlay()
        update_overlay.set_child(update_btn)
        update_overlay.add_overlay(badge_label)
        update_overlay.set_visible(False)
        header_bar.pack_start(update_overlay)

        appstream_repository = AppstreamRepository()

        # --- Top-level ViewStack (Home / Bundles / Installed / Pending) ---
        view_stack = Adw.ViewStack()
        view_stack.set_vexpand(True)
        view_stack.set_hexpand(True)

        view_switcher = Adw.ViewSwitcher()
        view_switcher.set_stack(view_stack)
        view_switcher.set_policy(Adw.ViewSwitcherPolicy.WIDE)
        header_bar.set_title_widget(view_switcher)

        # Home page content
        home_box = self._build_home_page(appstream_repository)
        view_stack.add_titled_with_icon(home_box, "home", _("Home"), "go-home-symbolic")

        # Categories tab
        categories_scroll = Gtk.ScrolledWindow()
        categories_scroll.set_vexpand(True)
        categories_scroll.set_hexpand(True)
        categories_scroll.set_child(self._create_category_bar(appstream_repository))
        view_stack.add_titled_with_icon(
            categories_scroll, "categories", _("Categories"), "view-app-grid-symbolic"
        )

        bundles_scroll = Gtk.ScrolledWindow()
        bundles_scroll.set_vexpand(True)
        bundles_scroll.set_hexpand(True)
        bundles_scroll.set_child(self._create_bundle_bar(appstream_repository))
        view_stack.add_titled_with_icon(
            bundles_scroll, "bundles", _("Bundles"), "folder-symbolic"
        )

        installed_page = InstalledPage(
            appstream_repository,
            lambda p: self.navigation_view.push(p),
        )
        view_stack.add_titled_with_icon(
            installed_page, "installed", _("Installed"), "drive-harddisk-symbolic"
        )

        def _on_installed_tab_shown(_stack, _param):
            if view_stack.get_visible_child_name() == "installed":
                installed_page.refresh()

        view_stack.connect("notify::visible-child", _on_installed_tab_shown)

        queue_service = InstallQueueService()
        pending_page = PendingPage(
            queue_service,
            lambda p: self.navigation_view.push(p),
        )
        pending_stack_page = view_stack.add_titled_with_icon(
            pending_page, "pending", _("Pending"), "emblem-downloads-symbolic"
        )

        def _update_pending_badge():
            count = sum(
                1 for item in queue_service.get_all() if item.status == "installing"
            )
            pending_stack_page.set_badge_number(count)

        def _on_queue_changed():
            items = queue_service.get_all()
            if items:
                item = items[-1]
                item.subscribe_status(lambda _s: _update_pending_badge())
                toast = Adw.Toast.new(
                    _("{name} is installing — track progress in Pending").format(
                        name=item.app_name
                    )
                )
                toast.set_timeout(1)
                self._toast_overlay.add_toast(toast)
            _update_pending_badge()

        queue_service.subscribe_changes(_on_queue_changed)

        # Search bar (centered, ~70% width) above the view stack
        search_entry = Gtk.SearchEntry()
        search_entry.set_placeholder_text(_("Search…"))
        search_entry.set_hexpand(True)

        search_entry.connect(
            "search-changed", self._on_search_focus, appstream_repository
        )

        search_clamp = Adw.Clamp()
        search_clamp.set_maximum_size(700)
        search_clamp.set_margin_top(12)
        search_clamp.set_margin_bottom(18)
        search_clamp.set_child(search_entry)

        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        content_box.append(search_clamp)
        content_box.append(view_stack)

        toolbar_view.set_content(content_box)

        return toolbar_view

    def _build_home_page(self, appstream_repository: AppstreamRepository) -> Gtk.Widget:
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
            (_("New"), get_home_content_uc.get_added_appstream_list()),
            (_("Updated"), get_home_content_uc.get_updated_appstream_list()),
            (_("Trending"), get_home_content_uc.get_trending_appstream_list()),
            (_("Popular"), get_home_content_uc.get_popular_appstream_list()),
        ]

        for title, app_list in tabs:
            scroll = Gtk.ScrolledWindow()
            scroll.set_vexpand(True)
            scroll.set_hexpand(True)
            scroll.set_child(
                self._get_application_list_widget(app_list, appstream_repository)
            )
            stack.add_titled(scroll, title.lower(), title)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        box.append(stack_switcher)
        box.append(stack)

        return box

    def _on_categories_clicked(self, _btn):
        self.navigation_view.push(self._build_categories_page(AppstreamRepository()))

    def _build_categories_page(
        self, appstream_repository: AppstreamRepository
    ) -> Adw.NavigationPage:
        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._create_category_bar(appstream_repository))
        toolbar_view.set_content(scroll)

        page = Adw.NavigationPage.new(toolbar_view, _("Categories"))
        return page

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
        flow.set_max_children_per_line(5)
        flow.set_min_children_per_line(2)
        flow.set_homogeneous(False)
        flow.set_row_spacing(12)
        flow.set_column_spacing(12)
        flow.set_margin_top(24)
        flow.set_margin_bottom(24)
        flow.set_margin_start(24)
        flow.set_margin_end(24)
        flow.set_halign(Gtk.Align.CENTER)

        for category in CategoryRepository().get_all():
            icon_name = category_icons.get(
                category, "application-x-executable-symbolic"
            )

            card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            card_box.add_css_class("card")
            card_box.set_size_request(220, 160)
            card_box.set_halign(Gtk.Align.CENTER)
            card_box.set_valign(Gtk.Align.CENTER)

            apps = appstream_repository.get_summary_list_by_category_id(category)

            for row_apps in [apps[:4], apps[4:8]]:
                if not row_apps:
                    break
                row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
                row_box.set_halign(Gtk.Align.CENTER)
                row_box.set_margin_start(16)
                row_box.set_margin_end(16)
                for app in row_apps:
                    app_icon = Gtk.Image.new_from_file(app.getIcon())
                    app_icon.set_pixel_size(36)
                    row_box.append(app_icon)
                card_box.append(row_box)

            card_box.get_first_child().set_margin_top(16)

            # Category name + symbolic icon
            footer_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            footer_box.set_halign(Gtk.Align.CENTER)
            footer_box.set_margin_top(14)
            footer_box.set_margin_bottom(16)

            cat_icon = Gtk.Image.new_from_icon_name(icon_name)
            cat_icon.set_pixel_size(16)
            footer_box.append(cat_icon)

            label = Gtk.Label(label=_(category))
            label.add_css_class("heading")
            footer_box.append(label)

            card_box.append(footer_box)

            btn = Gtk.Button()
            btn.add_css_class("flat")
            btn.set_child(card_box)
            btn.connect(
                "clicked",
                self._on_category_clicked,
                category,
                icon_name,
                appstream_repository,
            )
            flow.append(btn)

        return flow

    def _create_bundle_bar(self, appstream_repository: AppstreamRepository):
        bundle_uc = GetBundleContentUc(BundleRepository())

        flow = Gtk.FlowBox()
        flow.set_selection_mode(Gtk.SelectionMode.NONE)
        flow.set_max_children_per_line(5)
        flow.set_min_children_per_line(2)
        flow.set_homogeneous(False)
        flow.set_row_spacing(12)
        flow.set_column_spacing(12)
        flow.set_margin_top(24)
        flow.set_margin_bottom(24)
        flow.set_margin_start(24)
        flow.set_margin_end(24)
        flow.set_halign(Gtk.Align.CENTER)

        for bundle in bundle_uc.get_list():
            card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            card_box.add_css_class("card")
            card_box.set_size_request(220, 160)
            card_box.set_halign(Gtk.Align.CENTER)
            card_box.set_valign(Gtk.Align.CENTER)

            apps = appstream_repository.get_list_by_id_list(
                bundle.get_application_list()[:4]
            )

            icons_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            icons_box.set_halign(Gtk.Align.CENTER)
            icons_box.set_margin_start(16)
            icons_box.set_margin_end(16)
            icons_box.set_margin_top(16)
            for app in apps[:4]:
                app_icon = Gtk.Image.new_from_file(app.getIcon())
                app_icon.set_pixel_size(36)
                icons_box.append(app_icon)
            card_box.append(icons_box)

            footer_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            footer_box.set_halign(Gtk.Align.CENTER)
            footer_box.set_margin_top(14)
            footer_box.set_margin_bottom(16)

            bundle_icon = Gtk.Image.new_from_icon_name("folder-symbolic")
            bundle_icon.set_pixel_size(16)
            footer_box.append(bundle_icon)

            label = Gtk.Label(label=bundle.id)
            label.add_css_class("heading")
            footer_box.append(label)

            card_box.append(footer_box)

            btn = Gtk.Button()
            btn.add_css_class("flat")
            btn.set_child(card_box)
            btn.connect(
                "clicked", self._on_bundle_clicked, bundle, appstream_repository
            )
            flow.append(btn)

        return flow

    def _on_bundle_clicked(self, _btn, bundle, appstream_repository):
        self.navigation_view.push(BundleDetailPage(bundle, appstream_repository))

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

    def _on_search_focus(
        self, entry: Gtk.SearchEntry, appstream_repository: AppstreamRepository
    ):
        if not isinstance(self.navigation_view.get_visible_page(), SearchListPage):
            self.navigation_view.push(
                SearchListPage(entry.get_text(), appstream_repository)
            )

    def _on_category_clicked(
        self,
        _button,
        category: str,
        icon_name: str,
        appstream_repository: AppstreamRepository,
    ):
        self.navigation_view.push(
            CategoryListPage(category, icon_name, appstream_repository)
        )

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
