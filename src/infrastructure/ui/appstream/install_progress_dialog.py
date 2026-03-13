import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib


class InstallProgressDialog(Adw.Dialog):

    def __init__(self):
        super().__init__()
        self.set_title(_("Installing…"))
        self.set_content_width(640)
        self.set_content_height(420)
        self.set_can_close(False)

        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        text_view = Gtk.TextView()
        text_view.set_editable(False)
        text_view.set_monospace(True)
        text_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        text_view.set_margin_start(8)
        text_view.set_margin_end(8)
        text_view.set_margin_top(8)
        text_view.set_margin_bottom(8)
        self._buffer = text_view.get_buffer()

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.set_child(text_view)
        self._scroll = scroll

        self._close_btn = Gtk.Button(label=_("Close"))
        self._close_btn.set_sensitive(False)
        self._close_btn.set_halign(Gtk.Align.END)
        self._close_btn.set_margin_top(8)
        self._close_btn.set_margin_bottom(12)
        self._close_btn.set_margin_end(12)
        self._close_btn.connect("clicked", lambda _: self.force_close())

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        box.set_margin_top(12)
        box.set_margin_start(12)
        box.set_margin_end(12)
        box.append(scroll)
        box.append(self._close_btn)

        toolbar_view.set_content(box)
        self.set_child(toolbar_view)

    def append_line(self, text: str):
        self._buffer.insert(self._buffer.get_end_iter(), text)
        adj = self._scroll.get_vadjustment()
        adj.set_value(adj.get_upper() - adj.get_page_size())

    def mark_done(self):
        self._close_btn.set_sensitive(True)
        self.set_can_close(True)
