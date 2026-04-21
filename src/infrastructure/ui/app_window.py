from domain.UseCase.export_uc import ExportUc
from domain.UseCase.import_uc import ImportUc
from domain.UseCase.get_home_content_uc import GetHomeContentUC
from domain.entity.application_version_entity import ApplicationVersionEntity
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.appstream_page import AppstreamPage
from infrastructure.ui.home.bundle_page import BundlePage
from infrastructure.ui.home.category_page import CategoryPage
from infrastructure.service.install_queue_service import InstallQueueService
from infrastructure.ui.home.installed_page import InstalledPage
from infrastructure.ui.home.pending_list_page import PendingPage
from infrastructure.ui.home.updates_page import UpdatesPage
from infrastructure.ui.search_list_page import SearchListPage
from infrastructure.ui.menu.import_dialog import ImportDialog
from infrastructure.ui.menu.parameters_dialog import ParametersDialog
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.repository.recipe_repository import RecipeRepository
from infrastructure.ui.appstream.flatpak_file_page import FlatpakFilePage
from infrastructure.ui.shared.app_list_grid_shared import AppListGridShared
from infrastructure.ui.shared.icons_shared import IconsShared

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

import json
import os
import threading

from gi.repository import Gdk, Gio, Gtk, Adw, GLib


class MainWindow(Adw.ApplicationWindow):

    def __init__(self, *args, init_fn=None, **kwargs):
        super().__init__(*args, **kwargs)

        self.set_title("Easy flatpak")
        self.set_default_size(1100, 800)
        self._pending_flatpak = None

        self._toast_overlay = Adw.ToastOverlay()
        self.set_content(self._toast_overlay)

        self.navigation_view = Adw.NavigationView()
        self._toast_overlay.set_child(self.navigation_view)

        self.connect("close-request", self._on_close_request)

        if init_fn:
            self._show_loading()
            self.connect("map", lambda w: threading.Thread(target=self._run_init, args=(init_fn,), daemon=True).start())
        else:
            self._build_home()

    def _show_loading(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_halign(Gtk.Align.CENTER)
        box.set_valign(Gtk.Align.CENTER)
        box.set_vexpand(True)
        spinner = Gtk.Spinner()
        spinner.set_spinning(True)
        spinner.set_size_request(48, 48)
        label = Gtk.Label(label=_("Loading…"))
        label.add_css_class("dim-label")
        box.append(spinner)
        box.append(label)
        loading_page = Adw.NavigationPage.new(box, "Easy flatpak")
        self.navigation_view.push(loading_page)

    def _run_init(self, init_fn):
        init_fn()
        GLib.idle_add(self._on_init_done)

    def _on_init_done(self):
        from domain.entity.user_settings_entity import UserSettingsEntity
        settings = UserSettingsEntity()
        style_manager = Adw.StyleManager.get_default()
        if settings.use_theme_dark():
            style_manager.set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        elif settings.use_theme_light():
            style_manager.set_color_scheme(Adw.ColorScheme.FORCE_LIGHT)
        else:
            style_manager.set_color_scheme(Adw.ColorScheme.DEFAULT)

        stack = self.navigation_view.get_navigation_stack()
        if stack.get_n_items() > 0:
            self.navigation_view.pop_to_page(stack.get_item(0))
            self.navigation_view.replace([self._create_home_page()])
        if self._pending_flatpak:
            self.open_flatpak_file(self._pending_flatpak)
            self._pending_flatpak = None
        return GLib.SOURCE_REMOVE

    def _build_home(self):
        home_page = self._create_home_page()
        self.navigation_view.push(home_page)

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
        menu.append(_("Install local Flatpak"), "win.open_flatpak")
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
            ("open_flatpak", self._on_menu_open_flatpak),
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
        view_stack.add_titled_with_icon(
            home_box,
            "home",
            _("Home"),
            IconsShared().find_icon_name_available(IconsShared.ICON_HOME),
        )

        # Categories tab
        view_stack.add_titled_with_icon(
            CategoryPage(appstream_repository, self.navigation_view.push),
            "categories",
            _("Categories"),
            IconsShared().find_icon_name_available(IconsShared.ICON_CATEGORIES),
        )

        view_stack.add_titled_with_icon(
            BundlePage(appstream_repository, self.navigation_view.push),
            "bundles",
            _("Bundles"),
            IconsShared().find_icon_name_available(IconsShared.ICON_BUNDLES),
        )

        installed_page = InstalledPage(
            appstream_repository,
            lambda p: self.navigation_view.push(p),
            on_import=self._on_menu_import,
            on_export=self._on_menu_export,
            on_open_flatpak=self.open_flatpak_file,
        )
        view_stack.add_titled_with_icon(
            installed_page,
            "installed",
            _("Installed"),
            IconsShared().find_icon_name_available(IconsShared.ICON_INSTALLED),
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
            updates_page,
            "updates",
            _("Updates"),
            IconsShared().find_icon_name_available(IconsShared.ICON_UPDATES),
        )
        updates_stack_page.set_visible(False)

        queue_service = InstallQueueService()
        pending_page = PendingPage(
            queue_service,
            lambda p: self.navigation_view.push(p),
        )
        pending_stack_page = view_stack.add_titled_with_icon(
            pending_page,
            "pending",
            _("Pending"),
            IconsShared().find_icon_name_available(IconsShared.ICON_PENDING),
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
                app.get_branding_dark()
                if style_manager.get_dark()
                else app.get_branding_light()
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

        def _auto_advance():
            n = carousel.get_n_pages()
            if n == 0:
                return GLib.SOURCE_REMOVE
            next_idx = (round(carousel.get_position()) + 1) % n
            carousel.scroll_to(carousel.get_nth_page(next_idx), True)
            return GLib.SOURCE_CONTINUE

        GLib.timeout_add_seconds(3, _auto_advance)

        wrapper = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        wrapper.append(carousel)
        wrapper.append(dots)
        return wrapper

    def _get_application_list_widget(self, application_list, appstream_repository):
        grid = AppListGridShared()
        for app in application_list:
            grid.append(app, self._on_app_clicked, appstream_repository)
        return grid.get_widget()

    def _on_menu_parameters(self, _action, _param):
        ParametersDialog().present(self)

    def _on_menu_open_flatpak(self, _action, _param):
        file_dialog = Gtk.FileDialog.new()
        file_dialog.set_title(_("Install local Flatpak"))
        filter_flatpak = Gtk.FileFilter()
        filter_flatpak.set_name(_("Flatpak files"))
        filter_flatpak.add_pattern("*.flatpak")
        filters = Gio.ListStore.new(Gtk.FileFilter)
        filters.append(filter_flatpak)
        file_dialog.set_filters(filters)
        file_dialog.open(self, None, self._on_menu_open_flatpak_chosen)

    def _on_menu_open_flatpak_chosen(self, file_dialog, result):
        try:
            file = file_dialog.open_finish(result)
        except GLib.Error:
            return
        self.open_flatpak_file(file.get_path())

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
        about.set_version(ApplicationVersionEntity().get_current_version())
        about.set_developer_name("Michael Bertocchi")
        about.set_license_type(Gtk.License.LGPL_2_1)
        about.set_website("https://dupot.org")
        about.present(self)

    def _on_search_button_clicked(self, _, appstream_repository: AppstreamRepository):
        if not isinstance(self.navigation_view.get_visible_page(), SearchListPage):
            self.navigation_view.push(SearchListPage("", appstream_repository))

    def _on_app_clicked(
        self, _button, app_id: str, appstream_repository: AppstreamRepository
    ):
        app = appstream_repository.get_by_id(app_id)
        if app:
            self.navigation_view.push(AppstreamPage(app))

    def open_flatpak_file(self, file_path: str):
        page = FlatpakFilePage(file_path, self._navigate_home)
        self.navigation_view.push(page)

    def _navigate_home(self):
        stack = self.navigation_view.get_navigation_stack()
        if stack.get_n_items() > 1:
            self.navigation_view.pop_to_page(stack.get_item(0))
        return GLib.SOURCE_REMOVE

    def _on_close_request(self, _window):
        pending = [i for i in InstallQueueService().get_all() if i.status == "installing"]
        if not pending:
            return False

        dialog = Adw.AlertDialog()
        dialog.set_heading(_("Processes still running"))
        dialog.set_body(_("Some installations are still in progress. Are you sure you want to close?"))
        dialog.add_response("cancel", _("Cancel"))
        dialog.add_response("close", _("Close anyway"))
        dialog.set_response_appearance("close", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_default_response("cancel")
        dialog.set_close_response("cancel")
        dialog.connect("response", self._on_close_confirmed)
        dialog.present(self)
        return True  # Prevent immediate close

    def _on_close_confirmed(self, dialog, response: str):
        if response == "close":
            self.destroy()


class AppWindow(Adw.Application):
    def __init__(self, init_fn=None):
        super().__init__(
            application_id="org.dupot.easyflatpak",
            flags=Gio.ApplicationFlags.HANDLES_OPEN,
        )
        self._init_fn = init_fn

    def do_activate(self):
        self._register_bundled_icons()
        win = MainWindow(application=self, init_fn=self._init_fn)
        win.present()

    def _register_bundled_icons(self):
        import os
        icons_path = os.path.join(
            os.path.dirname(__file__), "..", "..", "assets", "ui_icons"
        )
        icons_path = os.path.normpath(icons_path)
        theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default())
        theme.add_search_path(icons_path)

    def do_open(self, files, n_files, hint):
        self.activate()
        win = self.get_active_window()
        if not isinstance(win, MainWindow):
            return
        for f in files:
            path = f.get_path()
            if path and path.endswith(".flatpak"):
                if win._pending_flatpak is not None or not win.navigation_view.get_visible_page():
                    win._pending_flatpak = path
                else:
                    win.open_flatpak_file(path)
                break
