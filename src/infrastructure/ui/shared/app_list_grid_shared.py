import gi

gi.require_version("Gtk", "4.0")

from gi.repository import Gtk, Pango

_css_provider = Gtk.CssProvider()
_css_provider.load_from_string(
    """
.app-grid flowboxchild {
    background: transparent;
    padding: 0;
}
.app-grid flowboxchild:hover {
    background: transparent;
}
"""
)


def _make_square_card(app, on_click, *on_click_args) -> Gtk.Button:
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
    box.append(icon)

    title = Gtk.Label(label=app.getName())
    title.add_css_class("caption")
    title.set_wrap(True)
    title.set_justify(Gtk.Justification.CENTER)
    title.set_max_width_chars(14)
    title.set_lines(2)
    title.set_ellipsize(Pango.EllipsizeMode.END)
    title.set_margin_start(6)
    title.set_margin_end(6)
    title.set_margin_bottom(10)
    box.append(title)

    button.set_child(box)
    return button


def _make_list_card(app, on_click, *on_click_args) -> Gtk.Button:
    button = Gtk.Button()
    button.add_css_class("card")
    button.connect("clicked", on_click, app.id, *on_click_args)

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
    text_box.set_hexpand(False)
    text_box.set_size_request(CARD_WIDTH, -1)

    title = Gtk.Label(label=app.getName())
    title.add_css_class("heading")
    title.set_halign(Gtk.Align.START)
    title.set_max_width_chars(50)
    title.set_ellipsize(Pango.EllipsizeMode.END)
    text_box.append(title)

    summary = Gtk.Label(label=app.getSummary())
    summary.add_css_class("caption")
    summary.add_css_class("dim-label")
    summary.set_halign(Gtk.Align.START)
    summary.set_lines(2)
    summary.set_max_width_chars(30)
    summary.set_ellipsize(Pango.EllipsizeMode.END)
    text_box.append(summary)

    box.append(text_box)
    button.set_child(box)
    return button


CARD_WIDTH = 200
CARD_SPACING = 8


class AppListGridShared:

    def __init__(self, square: bool = False):
        self._square = square
        self._apps = []

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
            self._list_flow.set_homogeneous(False)
            self._list_flow.set_max_children_per_line(10)
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
        if self._square:
            self._flow_box.append(_make_square_card(app, on_click, *on_click_args))
        else:
            btn = _make_list_card(app, on_click, *on_click_args)
            btn.set_size_request(CARD_WIDTH, 76)

            child = Gtk.FlowBoxChild()
            child.set_halign(Gtk.Align.CENTER)
            child.set_size_request(CARD_WIDTH, 76)
            child.set_child(btn)
            self._list_flow.append(child)

    def clear(self):
        flow = self._flow_box if self._square else self._list_flow
        while child := flow.get_first_child():
            flow.remove(child)
