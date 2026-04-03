import gi
from infrastructure.ui.shared.icons_shared import IconsShared

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, Gdk

_css_provider = Gtk.CssProvider()
_css_provider.load_from_string(
    """
.app-grid flowboxchild { background: transparent; padding: 0; }
.app-grid flowboxchild:hover { background: transparent; }
"""
)

from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.repository.category_repository import CategoryRepository
from infrastructure.ui.category_list_page import CategoryListPage

class CategoryPage(Gtk.ScrolledWindow):

    def __init__(
        self,
        appstream_repository: AppstreamRepository,
        on_navigate,
    ):
        super().__init__()
        self._appstream_repository = appstream_repository
        self._on_navigate = on_navigate

        self.set_vexpand(True)
        self.set_hexpand(True)
        self.set_child(self._build_flow())

    def _build_flow(self) -> Gtk.FlowBox:
        flow = Gtk.FlowBox()
        flow.add_css_class("app-grid")
        flow.connect(
            "realize",
            lambda w: Gtk.StyleContext.add_provider_for_display(
                w.get_display(), _css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
            ),
        )
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
        flow.set_valign(Gtk.Align.START)

        for category in CategoryRepository().get_all():
            icon_loop = IconsShared().get_icon_by_name(category)
            flow.append(self._build_card(category, icon_loop))

        return flow

    def _build_card(self, category: str, cat_icon) -> Gtk.Button:
        card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        card_box.set_size_request(220, 180)
        card_box.set_halign(Gtk.Align.CENTER)
        card_box.set_valign(Gtk.Align.CENTER)

        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        header_box.set_halign(Gtk.Align.CENTER)
        header_box.set_valign(Gtk.Align.CENTER)
        header_box.set_margin_top(34)
        header_box.set_margin_bottom(18)

        cat_icon = cat_icon
        cat_icon.set_pixel_size(24)
        cat_icon.set_margin_end(6)

        header_box.append(cat_icon)

        label = Gtk.Label(label=_(category))
        label.add_css_class("heading")
        header_box.append(label)

        card_box.append(header_box)

        apps = self._appstream_repository.get_summary_list_by_category_id(category)
        for row_apps in [apps[:4], apps[4:8]]:
            if not row_apps:
                break
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            row_box.set_halign(Gtk.Align.CENTER)
            row_box.set_margin_start(16)
            row_box.set_margin_end(16)
            for app in row_apps:
                app_icon = Gtk.Image.new_from_file(app.getIcon())
                app_icon.set_pixel_size(18)
                row_box.append(app_icon)
            card_box.append(row_box)

        btn = Gtk.Button()
        btn.add_css_class("card")
        btn.set_child(card_box)
        btn.connect("clicked", self._on_card_clicked, category, cat_icon)
        return btn

    def _on_card_clicked(self, _btn, category: str, cat_icon):
        self._on_navigate(
            CategoryListPage(category, cat_icon, self._appstream_repository)
        )
