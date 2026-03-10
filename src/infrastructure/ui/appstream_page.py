import re
import threading
import urllib.request
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib, Gdk

from domain.entity.appstream_long_entity import AppstreamLongEntity


def _webp_to_png(data: bytes) -> bytes:
    import io
    from PIL import Image
    img = Image.open(io.BytesIO(data)).convert("RGBA")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


class AppstreamPage(Adw.NavigationPage):

    def __init__(self, app: AppstreamLongEntity):
        super().__init__()
        css = Gtk.CssProvider()
        css.load_from_string(
            ".verified-circle { background-color: @accent_bg_color;"
            " border-radius: 9999px; padding: 3px; }"
            " .verified-circle image { color: @accent_fg_color; }"
        )
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        self.set_title(app.name)
        self.set_child(self._build(app))

    def _build(self, app: AppstreamLongEntity) -> Gtk.Widget:

        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        outer_scroll = Gtk.ScrolledWindow()
        outer_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        outer_scroll.set_vexpand(True)

        page_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        outer_scroll.set_child(page_box)


        # --- Header: icon + name + developer + summary (clamped) ---
        header_group = Adw.PreferencesGroup()
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        info_box.set_halign(Gtk.Align.CENTER)
        info_box.set_margin_top(12)
        info_box.set_margin_bottom(12)

        image = Gtk.Image.new_from_file(app.getIcon())
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

        if app.is_flathub_verified():
            verified_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            verified_box.set_halign(Gtk.Align.CENTER)
            verified_box.set_valign(Gtk.Align.CENTER)

            circle = Gtk.Box()
            circle.set_valign(Gtk.Align.CENTER)
            circle.add_css_class("verified-circle")

            check = Gtk.Image.new_from_icon_name("object-select-symbolic")
            check.set_pixel_size(10)
            circle.append(check)

            verified_lbl = Gtk.Label(label=app.get_flathub_verified_label())
            verified_lbl.add_css_class("caption")
            verified_lbl.add_css_class("accent")
            verified_box.append(circle)
            verified_box.append(verified_lbl)

            info_box.append(verified_box)

        if app.summary:
            summary_label = Gtk.Label(label=app.summary)
            summary_label.set_halign(Gtk.Align.CENTER)
            summary_label.set_wrap(True)
            info_box.append(summary_label)

        header_row = Adw.PreferencesRow()
        header_row.set_child(info_box)
        header_group.add(header_row)

        header_clamp = Adw.Clamp()
        header_clamp.set_maximum_size(800)
        header_clamp_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        header_clamp_box.set_margin_top(24)
        header_clamp_box.set_margin_bottom(12)
        header_clamp_box.set_margin_start(12)
        header_clamp_box.set_margin_end(12)
        header_clamp_box.append(header_group)
        header_clamp.set_child(header_clamp_box)
        page_box.append(header_clamp)

        # --- Screenshots (full width) ---
        screenshots_widget = self._build_screenshots_section(app)
        if screenshots_widget:
            page_box.append(screenshots_widget)

        # --- Details + description (clamped) ---
        details_clamp = Adw.Clamp()
        details_clamp.set_maximum_size(800)
        details_clamp_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        details_clamp_box.set_margin_top(12)
        details_clamp_box.set_margin_bottom(24)
        details_clamp_box.set_margin_start(12)
        details_clamp_box.set_margin_end(12)
        details_clamp.set_child(details_clamp_box)

        details_group = Adw.PreferencesGroup()
        details_group.set_title(_("Details"))

        if app.project_license:
            row = Adw.ActionRow()
            row.set_title(_("License"))
            row.set_subtitle(app.project_license)
            details_group.add(row)

        if app._download_size:
            row = Adw.ActionRow()
            row.set_title(_("Download Size"))
            row.set_subtitle(app.get_download_size())
            details_group.add(row)

        if app._installed_size:
            row = Adw.ActionRow()
            row.set_title(_("Installed Size"))
            row.set_subtitle(app.get_installed_size())
            details_group.add(row)

        details_clamp_box.append(details_group)

        if app.description:
            description_group = Adw.PreferencesGroup()
            description_group.set_title(_("Description"))

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
            details_clamp_box.append(description_group)

        page_box.append(details_clamp)

        toolbar_view.set_content(outer_scroll)

        return toolbar_view

    def _build_screenshots_section(self, app: AppstreamLongEntity):
        try:
            screenshots = app.get_screenshot_list()
        except Exception:
            return None

        if not screenshots:
            return None

        section_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        section_box.set_hexpand(True)

        title = Gtk.Label(label=_("Screenshots"))
        title.add_css_class("heading")
        title.set_halign(Gtk.Align.START)
        title.set_margin_start(16)
        title.set_margin_top(16)
        section_box.append(title)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
        scroll.set_min_content_height(230)
        scroll.set_hexpand(True)

        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        hbox.set_margin_top(8)
        hbox.set_margin_bottom(8)
        hbox.set_margin_start(8)
        hbox.set_margin_end(8)

        for screenshot in screenshots:
            btn = Gtk.Button()
            btn.add_css_class("flat")

            picture = Gtk.Picture()
            picture.set_size_request(360, 210)
            picture.set_content_fit(Gtk.ContentFit.COVER)
            picture.add_css_class("card")
            btn.set_child(picture)

            self._load_image_async(picture, screenshot.preview)
            btn.connect("clicked", self._on_screenshot_clicked, screenshot.large)
            hbox.append(btn)

        scroll.set_child(hbox)
        section_box.append(scroll)

        return section_box

    def _load_image_async(self, picture: Gtk.Picture, url: str):
        def fetch():
            try:
                data = urllib.request.urlopen(url).read()
                print(f"[img] fetched {len(data)} bytes from {url}")
                png_bytes = _webp_to_png(data)
                print(f"[img] converted to png: {len(png_bytes)} bytes")
                def apply():
                    texture = Gdk.Texture.new_from_bytes(GLib.Bytes.new(png_bytes))
                    picture.set_paintable(texture)
                    print(f"[img] applied texture to picture")
                GLib.idle_add(apply)
            except Exception as e:
                import traceback
                print(f"[img] ERROR: {e}")
                traceback.print_exc()

        threading.Thread(target=fetch, daemon=True).start()

    def _on_screenshot_clicked(self, _btn, url: str):
        dialog = Adw.Dialog()
        dialog.set_title("")
        dialog.set_content_width(900)
        dialog.set_content_height(600)

        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        picture = Gtk.Picture()
        picture.set_content_fit(Gtk.ContentFit.CONTAIN)
        picture.set_vexpand(True)
        picture.set_hexpand(True)

        spinner = Gtk.Spinner()
        spinner.set_spinning(True)
        spinner.set_halign(Gtk.Align.CENTER)
        spinner.set_valign(Gtk.Align.CENTER)

        overlay = Gtk.Overlay()
        overlay.set_child(picture)
        overlay.add_overlay(spinner)

        toolbar_view.set_content(overlay)
        dialog.set_child(toolbar_view)
        dialog.present(self)

        def fetch():
            try:
                data = urllib.request.urlopen(url).read()
                png_bytes = _webp_to_png(data)
                def apply():
                    texture = Gdk.Texture.new_from_bytes(GLib.Bytes.new(png_bytes))
                    picture.set_paintable(texture)
                    spinner.set_spinning(False)
                    spinner.set_visible(False)
                GLib.idle_add(apply)
            except Exception:
                GLib.idle_add(spinner.set_spinning, False)
                GLib.idle_add(spinner.set_visible, False)

        threading.Thread(target=fetch, daemon=True).start()
