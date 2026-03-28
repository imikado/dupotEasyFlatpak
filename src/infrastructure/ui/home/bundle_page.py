import gi
from infrastructure.ui.shared.icons_shared import IconsShared

gi.require_version("Gtk", "4.0")

from gi.repository import Gtk

_css_provider = Gtk.CssProvider()
_css_provider.load_from_string(
    """
.app-grid flowboxchild { background: transparent; padding: 0; }
.app-grid flowboxchild:hover { background: transparent; }
"""
)

from domain.UseCase.get_bundle_content_uc import GetBundleContentUc
from domain.conf.path_conf import PathConf
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.repository.bundle_repository import BundleRepository
from infrastructure.ui.bundle_detail_page import BundleDetailPage


class BundlePage(Gtk.ScrolledWindow):

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

        for bundle in GetBundleContentUc(BundleRepository()).get_list():
            flow.append(self._build_card(bundle))

        return flow

    def _build_card(self, bundle) -> Gtk.Button:
        card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        card_box.set_size_request(220, 160)
        card_box.set_halign(Gtk.Align.CENTER)
        card_box.set_valign(Gtk.Align.CENTER)

        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        header_box.set_halign(Gtk.Align.CENTER)
        header_box.set_margin_top(34)
        header_box.set_margin_bottom(18)

        bundle_icon = IconsShared().get_icon_by_name(bundle.get_icon())
        bundle_icon.set_pixel_size(24)
        bundle_icon.set_margin_end(6)

        header_box.append(bundle_icon)

        label = Gtk.Label(label=_(bundle.label))
        label.add_css_class("heading")
        header_box.append(label)

        card_box.append(header_box)

        apps = self._appstream_repository.get_list_by_id_list(
            bundle.get_application_list()[:4]
        )

        icons_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        icons_box.set_halign(Gtk.Align.CENTER)
        icons_box.set_margin_start(16)
        icons_box.set_margin_end(16)
        icons_box.set_valign(Gtk.Align.CENTER)
        for app in apps:
            app_icon = Gtk.Image.new_from_file(app.getIcon())
            app_icon.set_pixel_size(18)
            icons_box.append(app_icon)

        card_box.append(icons_box)

        btn = Gtk.Button()
        btn.add_css_class("card")
        btn.set_child(card_box)
        btn.connect("clicked", self._on_card_clicked, bundle)
        return btn

    def _on_card_clicked(self, _btn, bundle):
        self._on_navigate(BundleDetailPage(bundle, self._appstream_repository))
