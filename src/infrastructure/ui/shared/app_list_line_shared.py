import gi
import subprocess
import threading
from domain.UseCase.get_recipe_content_uc import GetRecipeContentUc
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.repository.recipe_repository import RecipeRepository
from infrastructure.service.install_queue_service import InstallQueueService

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")

from gi.repository import GLib, Gtk, Pango
from infrastructure.ui.shared.icons_shared import IconsShared

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

.small-button {
    padding: 4px 8px;
    font-size: smaller;
    min-height: 0;
}
"""
)


CARD_WIDTH = 340
CARD_SPACING = 8


def _make_icon_with_badge(
    icon: Gtk.Image, installed: bool, pixel_size: int
) -> Gtk.Widget:
    if not installed:
        return icon

    badge_icon = IconsShared().get_icon_by_name(IconsShared.ICON_CHECKMARK)
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


def _make_list_card(
    app, on_click, installed: bool = False, has_recipe: bool = False, *on_click_args
) -> Gtk.Widget:
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
    title.set_max_width_chars(32)
    title.set_ellipsize(Pango.EllipsizeMode.END)
    title.set_wrap(False)  # Titles usually shouldn't wrap in this layout
    text_box.append(title)

    summary = Gtk.Label(label=app.getSummary())
    summary.set_halign(Gtk.Align.START)
    summary.add_css_class("caption")
    summary.add_css_class("dim-label")

    summary.set_wrap(False)
    summary.set_lines(1)
    summary.set_ellipsize(Pango.EllipsizeMode.END)
    summary.set_max_width_chars(32)
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

        badge_icon = IconsShared().get_icon_by_name(IconsShared.ICON_CHECKMARK)
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

    # Use Overlay as card root so the install button can float above content
    # without being nested inside a Gtk.Button (which causes double-click issues)
    card = Gtk.Overlay()
    card.add_css_class("card")
    card.set_child(outer)

    # Navigation gesture on the overlay — fired for any click not claimed by a child
    nav = Gtk.GestureClick()
    nav.connect("released", lambda *_: on_click(card, app.id, *on_click_args))
    card.add_controller(nav)

    if not installed:
        install_label = _("Install with recipe") if has_recipe else _("Install")
        install_btn = Gtk.Button(label=install_label)
        install_btn.add_css_class("suggested-action")
        install_btn.add_css_class("small-button")
        # install_btn.add_css_class("pill")
        install_btn.set_halign(Gtk.Align.END)
        install_btn.set_valign(Gtk.Align.END)
        # install_btn.set_margin_end(10)
        install_btn.set_visible(False)
        card.add_overlay(install_btn)

        def on_install(_btn):
            from infrastructure.ui.appstream.install_dialog import InstallDialog

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
                                flatpak_api.get_override_filesystem_call(app.id, value)
                            )
                    result = flatpak_api.get_info_by_id(app.id)
                    GLib.idle_add(
                        queue_item.set_status,
                        "done" if result.returncode == 0 else "failed",
                    )

                threading.Thread(target=run_install, daemon=True).start()

            recipe_uc = GetRecipeContentUc(RecipeRepository())
            dialog = InstallDialog(app.id, has_recipe, recipe_uc, on_confirm)
            dialog.present(card.get_root())

        install_btn.connect("clicked", on_install)

        motion = Gtk.EventControllerMotion()
        motion.connect("enter", lambda *_: install_btn.set_visible(True))
        motion.connect("leave", lambda *_: install_btn.set_visible(False))
        card.add_controller(motion)

    return card


class AppListLineShared:

    def __init__(self):
        self._apps = []

        self._app_id_installed_list = FlatpakApi().get_installed_app_id_list()
        self._recipe_uc = GetRecipeContentUc(RecipeRepository())

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
        flow = self._list_flow
        while child := flow.get_first_child():
            flow.remove(child)
