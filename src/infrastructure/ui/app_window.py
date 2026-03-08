from domain.UseCase.get_home_content_uc import GetHomeContentUC
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.repository.category_repository import CategoryRepository
from infrastructure.ui.appstream_ui import AppstreamPage

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw


class MainWindow(Adw.ApplicationWindow):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.set_title("Nix Samba")
        self.set_default_size(900, 600)

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

        appstream_repository = AppstreamRepository()

        get_home_content_uc = GetHomeContentUC(
            ApiCacheRepository(), appstream_repository, FlathubApi(), SystemApi()
        )

        tab_view = Adw.TabView()
        tab_bar = Adw.TabBar()

        tab_bar.set_view(tab_view)

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
            page = tab_view.add_page(scroll)
            page.set_title(title)

        tab_view.connect("close-page", lambda _view, _page: True)
        tab_view.set_vexpand(True)
        tab_view.set_hexpand(True)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.append(tab_bar)
        box.append(tab_view)

        toolbar_view.set_content(box)
        toolbar_view.add_bottom_bar(self._create_category_bar())

        return toolbar_view

    def _create_category_bar(self):
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
            flow.append(btn)

        return flow

    def _get_application_list_widget(self, application_list, appstream_repository):
        flow_box = Gtk.FlowBox()
        flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
        flow_box.set_max_children_per_line(10)
        flow_box.set_min_children_per_line(3)
        flow_box.set_homogeneous(True)
        flow_box.set_row_spacing(8)
        flow_box.set_column_spacing(8)

        for app in application_list:
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            card.set_halign(Gtk.Align.CENTER)
            card.set_margin_top(12)
            card.set_margin_bottom(12)
            card.set_margin_start(8)
            card.set_margin_end(8)

            image = Gtk.Image.new_from_file(app.getIcon())
            image.set_pixel_size(64)
            image.set_halign(Gtk.Align.CENTER)
            card.append(image)

            title_label = Gtk.Label(label=app.getName())
            title_label.set_halign(Gtk.Align.CENTER)
            title_label.set_wrap(True)
            title_label.set_max_width_chars(12)
            title_label.add_css_class("caption")
            card.append(title_label)

            summary_label = Gtk.Label(label=app.getSummary())
            summary_label.set_halign(Gtk.Align.CENTER)
            summary_label.set_wrap(True)
            summary_label.set_max_width_chars(16)
            summary_label.set_lines(2)
            summary_label.set_ellipsize(3)  # PANGO_ELLIPSIZE_END
            summary_label.add_css_class("caption")
            summary_label.add_css_class("dim-label")
            card.append(summary_label)

            button = Gtk.Button()
            button.add_css_class("card")
            button.set_child(card)
            button.connect(
                "clicked", self._on_app_clicked, app.id, appstream_repository
            )
            flow_box.append(button)

        return flow_box

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
