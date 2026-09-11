import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw

from domain.entity.import_entity import ImportEntity
from infrastructure.ui.shared.icons_shared import IconsShared


class ImportDialog(Adw.Dialog):

    def __init__(self, import_list: list[ImportEntity], on_confirm):
        super().__init__()
        self.set_title(_("Import"))
        self.set_content_width(500)
        self.set_content_height(600)

        self._import_list = import_list
        self._on_confirm = on_confirm
        self._check_buttons: dict[str, Gtk.CheckButton] = {}
        self._rows: dict[str, Adw.ActionRow] = {}

        toolbar = Adw.ToolbarView()
        header = Adw.HeaderBar()
        toolbar.add_top_bar(header)

        select_all_btn = Gtk.Button(label=_("Select all"))
        select_all_btn.connect("clicked", self._on_select_all)
        header.pack_start(select_all_btn)

        unselect_all_btn = Gtk.Button(label=_("Unselect all"))
        unselect_all_btn.connect("clicked", self._on_unselect_all)
        header.pack_start(unselect_all_btn)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)

        list_box = Gtk.ListBox()
        list_box.add_css_class("boxed-list")
        list_box.set_selection_mode(Gtk.SelectionMode.NONE)
        list_box.set_margin_top(12)
        list_box.set_margin_bottom(12)
        list_box.set_margin_start(12)
        list_box.set_margin_end(12)

        for item in import_list:
            row = Adw.ActionRow()

            name = getattr(item, "name", None)
            summary = getattr(item, "summary", None)
            icon_path = getattr(item, "icon", None)

            row.set_title(name if name else item.app_id)
            subtitle_parts = []

            if summary:
                subtitle_parts.append(summary)
            subtitle_parts.append(item.installation_scope)
            if item.is_from_github():
                subtitle_parts.append(_("From GitHub"))
            elif not item.is_importable():
                subtitle_parts.append(_("Can't import without a URL"))
            row.set_subtitle("  ·  ".join(subtitle_parts))

            if icon_path:
                app_icon = Gtk.Image.new_from_file(icon_path)
                app_icon.set_pixel_size(32)
                row.add_prefix(app_icon)
            else:
                row.add_prefix(IconsShared.get_generic_app_icon(32))

            if not item.is_importable():
                warning_icon = IconsShared.get_warning_icon(16)
                warning_icon.set_tooltip_text(_("Can't import without a URL"))
                row.add_suffix(warning_icon)

            check = Gtk.CheckButton()
            check.set_active(item.is_importable())
            check.set_sensitive(item.is_importable())
            if not item.is_importable():
                check.set_tooltip_text(_("Can't import without a URL"))
            row.add_suffix(check)
            row.set_activatable_widget(check)

            self._check_buttons[item.app_id] = check
            self._rows[item.app_id] = row
            list_box.append(row)

        scroll.set_child(list_box)

        confirm_btn = Gtk.Button(label=_("Install"))
        confirm_btn.add_css_class("suggested-action")
        confirm_btn.add_css_class("pill")
        confirm_btn.set_halign(Gtk.Align.CENTER)
        confirm_btn.set_margin_top(12)
        confirm_btn.set_margin_bottom(12)
        confirm_btn.connect("clicked", self._on_confirm_clicked)

        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        content_box.append(scroll)
        content_box.append(confirm_btn)

        toolbar.set_content(content_box)
        self.set_child(toolbar)

    def apply_installed_ids(self, installed_ids: set):
        for app_id, check in self._check_buttons.items():
            if app_id not in installed_ids:
                continue
            check.set_active(False)
            check.set_sensitive(False)
            check.set_tooltip_text(_("Already installed"))

            row = self._rows.get(app_id)
            if row is not None:
                subtitle = row.get_subtitle() or ""
                row.set_subtitle(
                    "  ·  ".join(filter(None, [subtitle, _("Already installed")]))
                )

    def _on_select_all(self, _btn):
        for check in self._check_buttons.values():
            if check.get_sensitive():
                check.set_active(True)

    def _on_unselect_all(self, _btn):
        for check in self._check_buttons.values():
            check.set_active(False)

    def _on_confirm_clicked(self, _btn):
        selected_ids = [
            app_id
            for app_id, check in self._check_buttons.items()
            if check.get_active()
        ]
        self._on_confirm(selected_ids)
        self.close()
