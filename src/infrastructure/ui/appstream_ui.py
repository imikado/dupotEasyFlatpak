import os
import re
os.environ["WEBKIT_DISABLE_COMPOSITING_MODE"] = "1" 
# Fixes process crashes in sandboxed or specific driver environments
os.environ["WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS"] = "1"
# Prevents a specific GTK4 DMA buffer bug
os.environ["WEBKIT_DISABLE_DMABUF_RENDERER"] = "1"
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("WebKit", "6.0")

# Disable the sandbox to see if it's a process communication issue

from gi.repository import Gtk, Adw, WebKit, Gdk

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

        icon_path = os.path.expanduser(f'~/.data/Icons/{app.id.lower()}.png')
        image = Gtk.Image.new_from_file(icon_path)
        image.set_pixel_size(96)
        info_box.append(image)

        name_label = Gtk.Label(label=app.name)
        name_label.add_css_class('title-1')
        name_label.set_halign(Gtk.Align.CENTER)
        info_box.append(name_label)

        if app.developer_name:
            dev_label = Gtk.Label(label=app.developer_name)
            dev_label.add_css_class('dim-label')
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
        details_group.set_title(_('Details'))

        if app.project_license:
            row = Adw.ActionRow()
            row.set_title(_('License'))
            row.set_subtitle(app.project_license)
            details_group.add(row)

        pref_page.add(details_group)

        if app.description:
            description_group = Adw.PreferencesGroup()
            description_group.set_title("Description")

            clean_text = self.format_appstream_to_pango(app.description) 
            
            label = Gtk.Label(label=clean_text)
    
            # Enable HTML-like parsing
            label.set_use_markup(True)
            
            # UI Styling
            label.set_wrap(True)
            label.set_xalign(0)  # Left align
            label.set_selectable(True) # Allow users to copy the text
            
            # Add some padding so it doesn't touch the edges of the row
            label.set_margin_start(16)
            label.set_margin_end(16)
            label.set_margin_top(12)
            label.set_margin_bottom(12)

            desc_row = Adw.PreferencesRow()
            desc_row.set_child(label)
            description_group.add(desc_row)
            
            pref_page.add(description_group)

                 
         
        toolbar_view.set_content(pref_page)

        return toolbar_view

    def format_appstream_to_pango(self,html_text):
        if not html_text:
            return ""
        
        # 1. Replace <li> with a bullet point and </li> with a newline
        text = html_text.replace("<li>", "  • ").replace("</li>", "\n")
        
        # 2. Replace <p>, <ul>, and </ul> with newlines
        text = re.sub(r'</?p>|<ul>|</ul>', '\n', text)
        
        # 3. Handle bold/italic (Appstream uses <em> and <strong>, Pango uses <i> and <b>)
        text = text.replace("<em>", "<i>").replace("</em>", "</i>")
        text = text.replace("<strong>", "<b>").replace("</strong>", "</b>")
        
        # 4. Strip any other remaining tags (like <html> or <body>)
        text = re.sub(r'<[^>]+>', '', text)
        
        # 5. Clean up excessive newlines
        text = re.sub(r'\n\s*\n', '\n\n', text).strip()
        
        return text