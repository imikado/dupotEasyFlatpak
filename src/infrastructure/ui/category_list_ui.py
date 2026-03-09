import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import GLib, Gtk, Adw

from domain.UseCase.get_category_content_uc import GetCategoryContentUc
from infrastructure.repository.appstream_repository import AppstreamRepository

BATCH_SIZE = 20


class CategoryListPage(Adw.NavigationPage):

    def __init__(self, category: str, appstream_repository: AppstreamRepository):
        super().__init__()
        self.set_title(_(category))
        self._appstream_repository = appstream_repository
        self._flow_box = None
        self._pending = []
        self._idle_id = None
        self.set_child(self._build(category))

    def _build(self, category: str) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        self._flow_box = Gtk.FlowBox()
        self._flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self._flow_box.set_max_children_per_line(10)
        self._flow_box.set_min_children_per_line(3)
        self._flow_box.set_homogeneous(True)
        self._flow_box.set_row_spacing(8)
        self._flow_box.set_column_spacing(8)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(self._flow_box)

        toolbar_view.set_content(scroll)

        uc = GetCategoryContentUc(self._appstream_repository)
        self._pending = list(uc.get_app_list_by_category_id(category))
        self._idle_id = GLib.idle_add(self._append_batch)

        self.connect("hidden", self._cancel_pending)

        return toolbar_view

    def _append_batch(self) -> bool:
        if not self._pending:
            self._idle_id = None
            return GLib.SOURCE_REMOVE

        batch, self._pending = self._pending[:BATCH_SIZE], self._pending[BATCH_SIZE:]

        for app in batch:
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
            self._flow_box.append(button)

        return GLib.SOURCE_CONTINUE

    def _cancel_pending(self, _page):
        if self._idle_id is not None:
            GLib.source_remove(self._idle_id)
            self._idle_id = None
            self._pending = []

    def _on_app_clicked(self, _button, app_id: str):
        from infrastructure.ui.appstream_ui import AppstreamPage

        app = self._appstream_repository.get_by_id(app_id)
        if app:
            self.get_parent().push(AppstreamPage(app))
