from domain.UseCase.export_uc import ExportUc
from domain.UseCase.import_uc import ImportUc
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
from infrastructure.ui.updates_page import UpdatesPage
from infrastructure.ui.search_list_page import SearchListPage
from infrastructure.ui.import_dialog import ImportDialog
from infrastructure.ui.parameters_dialog import ParametersDialog
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.repository.recipe_repository import RecipeRepository
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

import json
import os
import threading

from gi.repository import Gio, Gtk, Adw, GLib


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
        menu.append(_("Import"), "win.import")
        menu.append(_("Export"), "win.export")
        menu.append(_("About"), "win.about")

        menu_button = Gtk.MenuButton()
        menu_button.set_icon_name("open-menu-symbolic")
        menu_button.set_menu_model(menu)
        header_bar.pack_end(menu_button)

        search_button = Gtk.Button()
        search_button.set_icon_name("system-search-symbolic")
        header_bar.pack_start(search_button)

        for name, callback in [
            ("parameters", self._on_menu_parameters),
            ("import", self._on_menu_import),
            ("export", self._on_menu_export),
            ("about", self._on_menu_about),
        ]:
            action = Gio.SimpleAction.new(name, None)
            action.connect("activate", callback)
            self.add_action(action)

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

        appstream_repository = AppstreamRepository()

        # --- Top-level ViewStack (Home / Categories / Bundles / Installed / Updates / Pending) ---
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

        updates_page = UpdatesPage(
            on_loaded=lambda count: (
                updates_stack_page.set_badge_number(count),
                updates_stack_page.set_visible(count > 0),
            )
        )
        updates_stack_page = view_stack.add_titled_with_icon(
            updates_page, "updates", _("Updates"), "software-update-available-symbolic"
        )
        updates_stack_page.set_visible(False)

        queue_service = InstallQueueService()
        pending_page = PendingPage(
            queue_service,
            lambda p: self.navigation_view.push(p),
        )
        pending_stack_page = view_stack.add_titled_with_icon(
            pending_page, "pending", _("Pending"), "emblem-downloads-symbolic"
        )
        pending_stack_page.set_visible(bool(queue_service.get_all()))

        def _update_pending_badge():
            count = sum(
                1 for item in queue_service.get_all() if item.status == "installing"
            )
            pending_stack_page.set_badge_number(count)

        def _on_queue_changed():
            items = queue_service.get_all()
            pending_stack_page.set_visible(bool(items))
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

        search_button.connect(
            "clicked", self._on_search_button_clicked, appstream_repository
        )

        toolbar_view.set_content(view_stack)

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
        apps_of_week = get_home_content_uc.get_apps_of_the_week()
        if apps_of_week:
            box.append(self._build_carousel(apps_of_week, appstream_repository))
        box.append(stack_switcher)
        box.append(stack)

        return box

    def _build_carousel(self, app_list: list, appstream_repository) -> Gtk.Widget:
        style_manager = Adw.StyleManager.get_default()
        display = self.get_display()

        carousel = Adw.Carousel()
        carousel.set_hexpand(True)
        carousel.set_allow_scroll_wheel(True)

        for app in app_list[:8]:
            color = (
                app.getBrandingDark()
                if style_manager.get_dark()
                else app.getBrandingLight()
            )
            safe_id = app.id.lower().replace(".", "-").replace("_", "-")
            css_class = f"carousel-card-{safe_id}"
            provider = Gtk.CssProvider()
            provider.load_from_string(f".{css_class} {{ background-color: {color}; }}")
            Gtk.StyleContext.add_provider_for_display(
                display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

            card = Gtk.Button()
            card.add_css_class("flat")
            card.add_css_class(css_class)
            card.set_hexpand(True)
            card.set_size_request(-1, 200)
            card.connect("clicked", self._on_app_clicked, app.id, appstream_repository)

            content = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=32)
            content.set_halign(Gtk.Align.CENTER)
            content.set_valign(Gtk.Align.CENTER)
            content.set_margin_top(24)
            content.set_margin_bottom(24)
            content.set_margin_start(48)
            content.set_margin_end(48)

            icon_path = app.getIcon()
            if os.path.exists(icon_path):
                icon_img = Gtk.Image.new_from_file(icon_path)
            else:
                icon_img = Gtk.Image.new_from_icon_name("application-x-executable")
            icon_img.set_pixel_size(96)
            icon_img.set_valign(Gtk.Align.CENTER)

            text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            text_box.set_valign(Gtk.Align.CENTER)

            name_label = Gtk.Label(label=app.getName())
            name_label.add_css_class("title-1")
            name_label.set_halign(Gtk.Align.START)
            name_label.set_wrap(True)
            name_label.set_max_width_chars(40)

            summary_label = Gtk.Label(label=app.getSummary())
            summary_label.add_css_class("body")
            summary_label.set_halign(Gtk.Align.START)
            summary_label.set_wrap(True)
            summary_label.set_max_width_chars(60)

            text_box.append(name_label)
            text_box.append(summary_label)
            content.append(icon_img)
            content.append(text_box)
            card.set_child(content)
            carousel.append(card)

        dots = Adw.CarouselIndicatorDots()
        dots.set_carousel(carousel)
        dots.set_margin_top(4)
        dots.set_margin_bottom(4)

        wrapper = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        wrapper.append(carousel)
        wrapper.append(dots)
        return wrapper

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
        ParametersDialog().present(self)

    def _on_menu_import(self, _action, _param):
        file_dialog = Gtk.FileDialog.new()
        file_dialog.set_title(_("Import"))
        documents = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DOCUMENTS)
        if documents:
            file_dialog.set_initial_folder(Gio.File.new_for_path(documents))
        file_dialog.open(self, None, self._on_import_file_chosen)

    def _on_import_file_chosen(self, file_dialog, result):
        try:
            file = file_dialog.open_finish(result)
        except GLib.Error:
            return
        path = file.get_path()
        import_uc = ImportUc(
            SystemApi(), FlatpakApi(), RecipeRepository(), AppstreamRepository()
        )
        import_list = import_uc.get_appstream_list(path)
        ImportDialog(
            import_list,
            lambda selected_ids: self._on_import_confirm(
                import_uc, import_list, selected_ids
            ),
        ).present(self)

    def _on_import_confirm(self, import_uc, import_list, selected_ids):
        threading.Thread(
            target=self._do_import,
            args=(import_uc, import_list, selected_ids),
            daemon=True,
        ).start()

    def _do_import(self, import_uc, import_list, selected_ids):
        filtered = import_uc.get_filtered_list(import_list, selected_ids)
        import_uc.process(filtered)

    def _on_menu_export(self, _action, _param):
        file_dialog = Gtk.FileDialog.new()
        file_dialog.set_title(_("Export"))
        file_dialog.set_initial_name(
            f"easyflatpak_export_{SystemApi().get_current_datetime_string()}.json"
        )
        documents = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DOCUMENTS)
        if documents:
            file_dialog.set_initial_folder(Gio.File.new_for_path(documents))
        file_dialog.save(self, None, self._on_export_file_chosen)

    def _on_export_file_chosen(self, file_dialog, result):
        try:
            file = file_dialog.save_finish(result)
        except GLib.Error:
            return
        path = file.get_path()
        threading.Thread(target=self._do_export, args=(path,), daemon=True).start()

    def _do_export(self, path):

        flatpak_api = FlatpakApi()
        recipe_repo = RecipeRepository()
        system_api = SystemApi()

        export_uc = ExportUc(system_api, flatpak_api, recipe_repo)
        export_uc.export(path)

        GLib.idle_add(self._on_export_done)

    def _on_export_done(self):
        self._toast_overlay.add_toast(Adw.Toast.new(_("Export saved")))
        return GLib.SOURCE_REMOVE

    def _on_menu_about(self, _action, _param):
        about = Adw.AboutDialog.new()
        about.set_application_name("Easy Flatpak")
        about.set_version("1.0")
        about.set_developer_name("dupot")
        about.set_license_type(Gtk.License.GPL_3_0)
        about.present(self)

    def _on_search_button_clicked(self, _, appstream_repository: AppstreamRepository):
        if not isinstance(self.navigation_view.get_visible_page(), SearchListPage):
            self.navigation_view.push(SearchListPage("", appstream_repository))

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
