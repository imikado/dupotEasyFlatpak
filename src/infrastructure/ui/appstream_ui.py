import os
import re
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw

from domain.entity.appstream_long_entity import AppstreamLongEntity


class AppstreamPage(Adw.NavigationPage):

    def __init__(self, app: AppstreamLongEntity):
        super().__init__()
        self.set_title(app.name)
        self.set_child(self._build(app))

    def _build(self, app: AppstreamLongEntity) -> Gtk.Widget:

        os.environ["WEBKIT_DISABLE_COMPOSITING_MODE"] = "1"

        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        pref_page = Adw.PreferencesPage()

        # Header group: icon + name + developer + summary wrapped in a PreferencesRow
        header_group = Adw.PreferencesGroup()

        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        info_box.set_halign(Gtk.Align.CENTER)
        info_box.set_margin_top(12)
        info_box.set_margin_bottom(12)

        icon_path = os.path.expanduser(f"~/.data/Icons/{app.id.lower()}.png")
        image = Gtk.Image.new_from_file(icon_path)
        image.set_pixel_size(96)
        info_box.append(image)

        name_label = Gtk.Label(label=app.name)
        name_label.add_css_class("title-1")
        name_label.set_halign(Gtk.Align.CENTER)
        info_box.append(name_label)

        if app.developer_name:
            dev_label = Gtk.Label(label=app.developer_name)
            dev_label.add_css_class("dim-label")
            dev_label.set_halign(Gtk.Align.CENTER)
            info_box.append(dev_label)

        if app.summary:
            summary_label = Gtk.Label(label=app.summary)
            summary_label.set_halign(Gtk.Align.CENTER)
            summary_label.set_wrap(True)
            info_box.append(summary_label)

        header_row = Adw.PreferencesRow()
        header_row.set_child(info_box)
        header_group.add(header_row)
        pref_page.add(header_group)

        # Details group
        details_group = Adw.PreferencesGroup()
        details_group.set_title(_("Details"))

        if app.project_license:
            row = Adw.ActionRow()
            row.set_title(_("License"))
            row.set_subtitle(app.project_license)
            details_group.add(row)

        pref_page.add(details_group)

        if app.description:
            description_group = Adw.PreferencesGroup()
            description_group.set_title("Description")

            markup = app.description
            markup = re.sub(
                r"<li>(.*?)</li>",
                lambda m: "• " + m.group(1).strip() + "\n",
                markup,
                flags=re.DOTALL,
            )
            markup = re.sub(
                r"<p>(.*?)</p>",
                lambda m: m.group(1).strip() + "\n",
                markup,
                flags=re.DOTALL,
            )
            markup = re.sub(r"<em>(.*?)</em>", r"<i>\1</i>", markup, flags=re.DOTALL)
            markup = re.sub(
                r"<strong>(.*?)</strong>", r"<b>\1</b>", markup, flags=re.DOTALL
            )
            markup = re.sub(
                r"<code>(.*?)</code>", r"<tt>\1</tt>", markup, flags=re.DOTALL
            )
            markup = re.sub(r"<[^>]+>", "", markup)
            markup = re.sub(r"[ \t]+", " ", markup)
            markup = re.sub(r"\n ", "\n", markup)
            markup = markup.strip()

            label = Gtk.Label(label=markup)
            label.set_use_markup(True)
            label.set_wrap(True)
            label.set_justify(Gtk.Justification.LEFT)
            label.set_xalign(0)
            label.set_margin_start(12)
            label.set_margin_end(12)
            label.set_margin_top(8)
            label.set_margin_bottom(8)

            desc_row = Adw.PreferencesRow()
            desc_row.set_child(label)
            description_group.add(desc_row)

            pref_page.add(description_group)

        toolbar_view.set_content(pref_page)

        return toolbar_view
