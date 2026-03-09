import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw

from domain.UseCase.get_category_content_uc import GetCategoryContentUc
from infrastructure.repository.appstream_repository import AppstreamRepository


class CategoryListPage(Adw.NavigationPage):

    def __init__(self, category: str, appstream_repository: AppstreamRepository):
        super().__init__()
        self.set_title(_(category))
        self._appstream_repository = appstream_repository
        self.set_child(self._build(category))

    def _build(self, category: str) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        uc = GetCategoryContentUc(self._appstream_repository)
        app_list = uc.get_app_list_by_category_id(category)

        flow_box = Gtk.FlowBox()
        flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
        flow_box.set_max_children_per_line(10)
        flow_box.set_min_children_per_line(3)
        flow_box.set_homogeneous(True)
        flow_box.set_row_spacing(8)
        flow_box.set_column_spacing(8)

        for app in app_list:
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
            button.connect("clicked", self._on_app_clicked, app.id)
            flow_box.append(button)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(flow_box)

        toolbar_view.set_content(scroll)
        return toolbar_view

    def _on_app_clicked(self, _button, app_id: str):
        from infrastructure.ui.appstream_ui import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
