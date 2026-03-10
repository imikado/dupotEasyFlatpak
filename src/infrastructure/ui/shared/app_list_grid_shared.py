import gi

gi.require_version("Gtk", "4.0")

from gi.repository import Gtk, Pango


def _make_app_card(app, on_click, *on_click_args) -> Gtk.Button:
    button = Gtk.Button()
    button.add_css_class("flat")
    button.connect("clicked", on_click, app.id, *on_click_args)

    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
    box.add_css_class("card")
    box.set_size_request(120, -1)
    box.set_margin_top(4)
    box.set_margin_bottom(4)
    box.set_margin_start(4)
    box.set_margin_end(4)

    icon = Gtk.Image.new_from_file(app.getIcon())
    icon.set_pixel_size(64)
    icon.set_margin_top(12)
    icon.set_margin_start(12)
    icon.set_margin_end(12)
    box.append(icon)

    title = Gtk.Label(label=app.getName())
    title.add_css_class("heading")
    title.set_wrap(True)
    title.set_justify(Gtk.Justification.CENTER)
    title.set_max_width_chars(15)
    title.set_margin_start(8)
    title.set_margin_end(8)
    box.append(title)

    summary = Gtk.Label(label=app.getSummary())
    summary.add_css_class("caption")
    summary.set_wrap(True)
    summary.set_justify(Gtk.Justification.CENTER)
    summary.set_max_width_chars(15)
    summary.set_lines(2)
    summary.set_ellipsize(Pango.EllipsizeMode.END)
    summary.set_margin_start(8)
    summary.set_margin_end(8)
    summary.set_margin_bottom(12)
    box.append(summary)

    button.set_child(box)
    return button


class AppListGridShared:

    def __init__(self):
        self._flow_box = Gtk.FlowBox()
        self._flow_box.set_valign(Gtk.Align.START)
        self._flow_box.set_max_children_per_line(6)
        self._flow_box.set_min_children_per_line(2)
        self._flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self._flow_box.set_homogeneous(True)
        self._flow_box.set_column_spacing(6)
        self._flow_box.set_row_spacing(6)
        self._flow_box.set_margin_top(12)
        self._flow_box.set_margin_bottom(12)
        self._flow_box.set_margin_start(12)
        self._flow_box.set_margin_end(12)

    def get_widget(self) -> Gtk.FlowBox:
        return self._flow_box

    def append(self, app, on_click, *on_click_args):
        self._flow_box.append(_make_app_card(app, on_click, *on_click_args))

    def clear(self):
        while child := self._flow_box.get_first_child():
            self._flow_box.remove(child)
