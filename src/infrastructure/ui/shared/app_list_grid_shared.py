import gi
import subprocess
import threading
from domain.UseCase.get_recipe_content_uc import GetRecipeContentUc
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.repository.recipe_repository import RecipeRepository
from infrastructure.service.install_queue_service import InstallQueueService

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")

from gi.repository import Gdk, GLib, Gtk, Pango

_css_provider = Gtk.CssProvider()
_css_provider.load_from_string(
    """
.app-grid flowboxchild {
    padding: 0;
    transition: all 200ms ease;
}

.card {
    border-radius: 12px;
    background-color: alpha(@window_fg_color, 0.05);
    border: 1px solid transparent;
}

.card:hover {
    background-color: alpha(@window_fg_color, 0.1);
    border: 1px solid alpha(@window_fg_color, 0.1);
}

 
"""
)


CARD_WIDTH = 320
CARD_SPACING = 8


def _make_icon_with_badge(
    icon: Gtk.Image, installed: bool, pixel_size: int
) -> Gtk.Widget:
    if not installed:
        return icon

    badge_icon = Gtk.Image.new_from_icon_name("object-select-symbolic")
    badge_icon.set_pixel_size(10)
    badge_icon.add_css_class("success")

    badge = Gtk.Box()
    badge.set_halign(Gtk.Align.END)
    badge.set_valign(Gtk.Align.END)
    badge.append(badge_icon)

    overlay = Gtk.Overlay()
    overlay.set_child(icon)
    overlay.add_overlay(badge)
    overlay.set_halign(Gtk.Align.CENTER)
    overlay.set_valign(Gtk.Align.CENTER)
    overlay.set_size_request(pixel_size, pixel_size)
    return overlay


def _make_square_card(
    app, on_click, installed: bool = False, *on_click_args
) -> Gtk.Button:
    button = Gtk.Button()
    button.add_css_class("flat")
    button.connect("clicked", on_click, app.id, *on_click_args)

    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
    box.set_halign(Gtk.Align.CENTER)
    box.set_valign(Gtk.Align.CENTER)
    box.add_css_class("card")
    box.set_size_request(120, 130)
    box.set_margin_top(4)
    box.set_margin_bottom(4)
    box.set_margin_start(4)
    box.set_margin_end(4)

    icon = Gtk.Image.new_from_file(app.getIcon())
    icon.set_pixel_size(56)
    icon.set_margin_top(16)
    icon.set_margin_start(8)
    icon.set_margin_end(8)
    box.append(_make_icon_with_badge(icon, installed, 56))

    title = Gtk.Label(label=app.getName())
    title.add_css_class("caption")
    title.set_wrap(True)
    title.set_max_width_chars(12)  # Slightly smaller to be safe
    title.set_lines(3)
    title.set_height_request(32)  # Force a fixed height for the text area
    title.set_ellipsize(Pango.EllipsizeMode.END)
    box.append(title)

    button.set_child(box)
    return button


def _make_list_card(
    app, on_click, installed: bool = False, has_recipe: bool = False, *on_click_args
) -> Gtk.Button:
    button = Gtk.Button()
    button.add_css_class("card")
    button.connect("clicked", on_click, app.id, *on_click_args)

    outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

    box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
    box.set_valign(Gtk.Align.CENTER)
    box.set_margin_top(8)
    box.set_margin_bottom(8)
    box.set_margin_start(12)
    box.set_margin_end(12)

    icon = Gtk.Image.new_from_file(app.getIcon())
    icon.set_pixel_size(48)
    box.append(icon)

    text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
    text_box.set_valign(Gtk.Align.CENTER)

    text_box.set_size_request(CARD_WIDTH - 80, -1)  # Subtract icon + spacing width
    text_box.set_hexpand(False)

    title = Gtk.Label(label=app.getName())
    title.add_css_class("heading")
    title.set_halign(Gtk.Align.START)
    title.set_ellipsize(Pango.EllipsizeMode.END)
    title.set_wrap(False)  # Titles usually shouldn't wrap in this layout
    text_box.append(title)

    summary = Gtk.Label(label=app.getSummary())
    summary.set_halign(Gtk.Align.START)
    summary.add_css_class("caption")
    summary.add_css_class("dim-label")

    # CRITICAL: Force wrapping and prevent pushing
    summary.set_wrap(True)
    summary.set_wrap_mode(Pango.WrapMode.WORD_CHAR)
    summary.set_lines(3)
    summary.set_ellipsize(Pango.EllipsizeMode.END)
    summary.set_max_width_chars(24)  # Limits horizontal "natural" size
    text_box.append(summary)

    box.append(text_box)
    outer.append(box)

    if installed:
        strip = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        strip.add_css_class("installed-strip")
        strip.set_halign(Gtk.Align.END)
        strip.set_margin_top(4)
        strip.set_margin_end(10)
        strip.set_margin_bottom(6)

        badge_icon = Gtk.Image.new_from_icon_name("object-select-symbolic")
        badge_icon.set_pixel_size(12)
        badge_icon.add_css_class("success")
        badge_icon.set_margin_start(8)

        badge_label = Gtk.Label(label=_("Installed"))
        badge_label.add_css_class("caption")
        badge_label.add_css_class("success")
        badge_label.set_margin_end(8)

        strip.append(badge_icon)
        strip.append(badge_label)
        outer.append(strip)

    button.set_child(outer)

    if not installed:
        gesture = Gtk.GestureClick()
        gesture.set_button(3)

        def on_right_click(g, _n, x, y):
            popover = Gtk.Popover()
            popover.set_parent(button)
            rect = Gdk.Rectangle()
            rect.x = int(x)
            rect.y = int(y)
            rect.width = 1
            rect.height = 1
            popover.set_pointing_to(rect)

            label = _("Install with recipe") if has_recipe else _("Install")
            install_btn = Gtk.Button(label=label)
            install_btn.add_css_class("suggested-action")
            install_btn.set_margin_top(4)
            install_btn.set_margin_bottom(4)
            install_btn.set_margin_start(4)
            install_btn.set_margin_end(4)

            def on_install(_btn):
                from infrastructure.ui.appstream.install_dialog import InstallDialog
                from domain.UseCase.get_recipe_content_uc import GetRecipeContentUc
                from infrastructure.repository.recipe_repository import RecipeRepository

                popover.popdown()

                def on_confirm(user_scope, active_permission_list):
                    queue_item = InstallQueueService().enqueue(app.id, app.getName())

                    def run_install():
                        flatpak_api = FlatpakApi()
                        flags = ["--user"] if user_scope else ["--system"]
                        process = subprocess.Popen(
                            flatpak_api.get_install_call(app.id, *flags),
                            stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT,
                            text=True,
                        )
                        for line in process.stdout:
                            GLib.idle_add(queue_item.append_output, line)
                        process.wait()
                        for perm, value in active_permission_list:
                            if perm.is_filesystem():
                                subprocess.run(
                                    flatpak_api.get_override_filesystem_call(
                                        app.id, value
                                    )
                                )
                        result = flatpak_api.get_info_by_id(app.id)
                        GLib.idle_add(
                            queue_item.set_status,
                            "done" if result.returncode == 0 else "failed",
                        )

                    threading.Thread(target=run_install, daemon=True).start()

                recipe_uc = GetRecipeContentUc(RecipeRepository())
                dialog = InstallDialog(app.id, has_recipe, recipe_uc, on_confirm)
                dialog.present(button.get_root())

            install_btn.connect("clicked", on_install)
            popover.set_child(install_btn)
            popover.popup()
            g.set_state(Gtk.EventSequenceState.CLAIMED)

        gesture.connect("pressed", on_right_click)
        button.add_controller(gesture)

    return button


class AppListGridShared:

    def __init__(self, square: bool = False):
        self._square = square
        self._apps = []

        self._app_id_installed_list = FlatpakApi().get_installed_app_id_list()
        self._recipe_uc = GetRecipeContentUc(RecipeRepository())

        if square:
            self._flow_box = Gtk.FlowBox()
            self._flow_box.add_css_class("app-grid")
            self._flow_box.connect(
                "realize",
                lambda w: Gtk.StyleContext.add_provider_for_display(
                    w.get_display(), _css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                ),
            )
            self._flow_box.set_valign(Gtk.Align.START)
            self._flow_box.set_halign(Gtk.Align.CENTER)
            self._flow_box.set_max_children_per_line(8)
            self._flow_box.set_min_children_per_line(3)
            self._flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
            self._flow_box.set_homogeneous(True)
            self._flow_box.set_column_spacing(6)
            self._flow_box.set_row_spacing(6)
            self._flow_box.set_margin_top(12)
            self._flow_box.set_margin_bottom(12)
            self._flow_box.set_margin_start(12)
            self._flow_box.set_margin_end(12)
            self._widget = self._flow_box
        else:
            self._list_flow = Gtk.FlowBox()
            self._list_flow.add_css_class("app-grid")
            self._list_flow.connect(
                "realize",
                lambda w: Gtk.StyleContext.add_provider_for_display(
                    w.get_display(), _css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                ),
            )
            self._list_flow.set_valign(Gtk.Align.START)
            self._list_flow.set_halign(Gtk.Align.CENTER)
            self._list_flow.set_selection_mode(Gtk.SelectionMode.NONE)
            self._list_flow.set_homogeneous(True)
            self._list_flow.set_min_children_per_line(2)
            self._list_flow.set_max_children_per_line(
                3
            )  # Force 2 columns like your screenshot
            self._list_flow.set_min_children_per_line(1)
            self._list_flow.set_column_spacing(CARD_SPACING)
            self._list_flow.set_row_spacing(CARD_SPACING)
            self._list_flow.set_margin_top(12)
            self._list_flow.set_margin_bottom(12)
            self._list_flow.set_margin_start(12)
            self._list_flow.set_margin_end(12)
            self._widget = self._list_flow

    def get_widget(self) -> Gtk.Widget:
        return self._widget

    def append(self, app, on_click, *on_click_args):
        installed = app.id in self._app_id_installed_list
        has_recipe = self._recipe_uc.has_recipe(app.id)
        if self._square:
            self._flow_box.append(
                _make_square_card(app, on_click, installed, *on_click_args)
            )
        else:
            btn = _make_list_card(app, on_click, installed, has_recipe, *on_click_args)
            btn.set_size_request(CARD_WIDTH, 76)
            btn.set_hexpand(False)
            btn.set_vexpand(False)

            child = Gtk.FlowBoxChild()
            child.set_halign(Gtk.Align.CENTER)
            child.set_size_request(CARD_WIDTH, 76)
            child.set_child(btn)
            self._list_flow.append(child)

    def clear(self):
        flow = self._flow_box if self._square else self._list_flow
        while child := flow.get_first_child():
            flow.remove(child)
