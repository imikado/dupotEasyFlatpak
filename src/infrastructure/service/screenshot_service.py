"""Automated screenshot generation.

Enabled by setting EASYFLATPAK_SCREENSHOT_DIR (see generate_screenshots.sh).
Each scene drives the real UI, waits for it to settle, renders the window
to a PNG via GSK (no external screenshot tool needed), then cleans up.
Nothing is installed/modified: every dialog gets a no-op confirm callback.
"""

import os
import tempfile

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Graphene", "1.0")

from gi.repository import Adw, GLib, Graphene, Gtk

ENV_DIR = "EASYFLATPAK_SCREENSHOT_DIR"
ENV_ONLY = "EASYFLATPAK_SCREENSHOT_ONLY"
ENV_DELAY = "EASYFLATPAK_SCREENSHOT_DELAY"
ENV_THEME = "EASYFLATPAK_SCREENSHOT_THEME"

SCREENSHOT_APP_ID = "com.valvesoftware.Steam"
SCREENSHOT_CATEGORY = "Game"
SCREENSHOT_SEARCH = "game"


def is_screenshot_mode() -> bool:
    return bool(os.environ.get(ENV_DIR))


def _noop(*_args, **_kwargs):
    pass


class ScreenshotService:

    def __init__(self, window):
        self._win = window
        self._out_dir = os.path.abspath(os.environ[ENV_DIR])
        self._delay_ms = int(os.environ.get(ENV_DELAY, "2500"))
        only = os.environ.get(ENV_ONLY, "").strip()
        self._only = {s.strip() for s in only.split(",") if s.strip()}
        self._dialog = None
        self._app_page = None
        os.makedirs(self._out_dir, exist_ok=True)

        self._scenes = [
            ("Screenshot_home", self._scene_tab("home")),
            ("Screenshot_category", self._scene_tab("categories")),
            ("Screenshot_category_grid", self._scene_category_list),
            ("Screenshot_bundles", self._scene_tab("bundles")),
            ("Screenshot_installed_applications", self._scene_tab("installed")),
            ("Screenshot_update_availables", self._scene_updates),
            ("Screenshot_search", self._scene_search),
            ("Screenshot_application_steam", self._scene_app_page),
            ("Screenshot_application_steam_install_setup_path", self._scene_install_dialog),
            ("Screenshot_override_view", self._scene_override_dialog),
            ("Screenshot_downgrade_view", self._scene_downgrade_dialog),
            ("Screenshot_settings", self._scene_settings),
            ("Screenshot_import_export", self._scene_import),
            ("Screenshot_features", self._scene_features),
        ]
        if self._only:
            self._scenes = [s for s in self._scenes if s[0] in self._only]

    # ---------------------------------------------------------------- driver

    def start(self):
        print(f"[screenshots] output: {self._out_dir}")
        theme = os.environ.get(ENV_THEME, "")
        schemes = {"dark": Adw.ColorScheme.FORCE_DARK, "light": Adw.ColorScheme.FORCE_LIGHT}
        if theme in schemes:
            Adw.StyleManager.get_default().set_color_scheme(schemes[theme])
        # ignore the real pointer: no hover highlight on cards
        self._win.navigation_view.set_can_target(False)
        GLib.timeout_add(self._delay_ms, self._next)

    def _next(self):
        self._reset()
        if not self._scenes:
            print("[screenshots] done")
            self._win.get_application().quit()
            return GLib.SOURCE_REMOVE

        name, setup = self._scenes.pop(0)
        print(f"[screenshots] {name}")
        try:
            ok = setup()
        except Exception as e:  # keep going on a broken scene
            print(f"[screenshots]   skipped ({e})")
            ok = False

        if ok is False:
            GLib.idle_add(self._next)
        else:
            GLib.timeout_add(self._delay_ms, self._capture_then_next, name)
        return GLib.SOURCE_REMOVE

    def _capture_then_next(self, name):
        path = os.path.join(self._out_dir, name + ".png")
        try:
            self._capture(path)
            print(f"[screenshots]   saved {path}")
        except Exception as e:
            print(f"[screenshots]   capture failed ({e})")
        GLib.idle_add(self._next)
        return GLib.SOURCE_REMOVE

    def _capture(self, path):
        win = self._win
        width, height = win.get_width(), win.get_height()
        snapshot = Gtk.Snapshot()
        Gtk.WidgetPaintable.new(win).snapshot(snapshot, width, height)
        node = snapshot.to_node()
        if node is None:
            raise RuntimeError("empty render")
        rect = Graphene.Rect().init(0, 0, width, height)
        texture = win.get_renderer().render_texture(node, rect)
        texture.save_to_png(path)

    def _reset(self):
        if self._dialog is not None:
            self._dialog.force_close()
            self._dialog = None
        nav = self._win.navigation_view
        stack = nav.get_navigation_stack()
        if stack.get_n_items() > 1:
            nav.pop_to_page(stack.get_item(0))
        self._app_page = None
        self._hide_tab("pending")
        self._set_tab("home")

    def _hide_tab(self, name):
        view_stack = getattr(self._win, "_view_stack", None)
        if view_stack is not None:
            view_stack.get_page(view_stack.get_child_by_name(name)).set_visible(False)

    def _set_tab(self, name):
        view_stack = getattr(self._win, "_view_stack", None)
        if view_stack is None:
            return False
        page = view_stack.get_page(view_stack.get_child_by_name(name))
        if not page.get_visible():
            return False
        view_stack.set_visible_child_name(name)
        return True

    def _present(self, dialog, parent=None):
        self._dialog = dialog
        dialog.present(parent or self._win)

    # ---------------------------------------------------------------- scenes

    def _scene_tab(self, name):
        return lambda: self._set_tab(name)

    def _scene_updates(self):
        if not self._set_tab("updates"):
            raise RuntimeError("no update available, Updates tab hidden")

    def _scene_category_list(self):
        from infrastructure.repository.appstream_repository import AppstreamRepository
        from infrastructure.ui.category_list_page import CategoryListPage
        from infrastructure.ui.shared.icons_shared import IconsShared

        self._set_tab("categories")
        icon = IconsShared().get_icon_by_name(SCREENSHOT_CATEGORY)
        self._win.navigation_view.push(
            CategoryListPage(SCREENSHOT_CATEGORY, icon, AppstreamRepository())
        )

    def _scene_search(self):
        from infrastructure.repository.appstream_repository import AppstreamRepository
        from infrastructure.ui.search_list_page import SearchListPage

        self._win.navigation_view.push(
            SearchListPage(SCREENSHOT_SEARCH, AppstreamRepository())
        )

    def _push_app_page(self):
        from infrastructure.repository.appstream_repository import AppstreamRepository
        from infrastructure.ui.appstream_page import AppstreamPage

        app = AppstreamRepository().get_by_id(SCREENSHOT_APP_ID)
        if app is None:
            raise RuntimeError(f"{SCREENSHOT_APP_ID} not in database")
        self._app_page = AppstreamPage(app)
        self._win.navigation_view.push(self._app_page)
        return self._app_page

    def _scene_app_page(self):
        self._push_app_page()

    def _scene_install_dialog(self):
        from infrastructure.ui.appstream.install_dialog import InstallDialog

        page = self._push_app_page()
        GLib.timeout_add(
            600,
            lambda: self._present(
                InstallDialog(
                    SCREENSHOT_APP_ID,
                    page._get_recipe_content.has_recipe(SCREENSHOT_APP_ID),
                    page._get_recipe_content,
                    _noop,
                    repo_id_list=["flathub"],
                ),
                page,
            ),
        )

    def _scene_override_dialog(self):
        from infrastructure.api.flatpak_api import FlatpakApi
        from infrastructure.ui.appstream.install_dialog import InstallDialog

        page = self._push_app_page()
        GLib.timeout_add(
            600,
            lambda: self._present(
                InstallDialog(
                    SCREENSHOT_APP_ID,
                    True,
                    page._get_recipe_content,
                    _noop,
                    heading=_("Recipe overrides"),
                    confirm_label=_("Apply"),
                    show_scope=False,
                    current_overrides=FlatpakApi().get_current_overrides(SCREENSHOT_APP_ID),
                ),
                page,
            ),
        )

    def _scene_downgrade_dialog(self):
        from infrastructure.api.flatpak_api import FlatpakApi
        from infrastructure.ui.appstream.downgrade_dialog import DowngradeDialog

        page = self._push_app_page()
        api = FlatpakApi()
        history = api.get_history_list_by_id(SCREENSHOT_APP_ID)
        if not history:
            raise RuntimeError(f"no history for {SCREENSHOT_APP_ID} (not installed?)")
        current = api.get_installed_commit_by_id(SCREENSHOT_APP_ID)
        GLib.timeout_add(
            600,
            lambda: self._present(DowngradeDialog(history, _noop, current), page),
        )

    def _scene_settings(self):
        from infrastructure.ui.menu.parameters_dialog import ParametersDialog

        self._present(ParametersDialog())

    def _scene_import(self):
        from infrastructure.api.flatpak_api import FlatpakApi
        from infrastructure.api.system_api import SystemApi
        from domain.UseCase.export_uc import ExportUc
        from domain.UseCase.import_uc import ImportUc
        from infrastructure.repository.appstream_repository import AppstreamRepository
        from infrastructure.repository.recipe_repository import RecipeRepository
        from infrastructure.ui.menu.import_dialog import ImportDialog

        self._set_tab("installed")
        args = (SystemApi(), FlatpakApi(), RecipeRepository(), AppstreamRepository())
        fd, path = tempfile.mkstemp(suffix=".json")
        os.close(fd)
        try:
            ExportUc(*args).export(path)
            import_list = ImportUc(*args).get_appstream_list(path)
        finally:
            os.unlink(path)
        if not import_list:
            raise RuntimeError("no installed application to export")
        self._present(ImportDialog(import_list, _noop))

    def _scene_features(self):
        from infrastructure.ui.menu.features_dialog import FeaturesDialog

        self._present(FeaturesDialog(_noop))
