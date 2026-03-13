import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from infrastructure.service.install_queue_service import InstallQueueService, InstallQueueItem


class PendingOutputPage(Adw.NavigationPage):

    def __init__(self, item: InstallQueueItem):
        super().__init__()
        self.set_title(item.app_name)
        self._item = item
        self._buffer = None
        self._scroll = None
        self.set_child(self._build())

        item.subscribe_output(self._on_new_line)
        self.connect("hidden", lambda _: item.unsubscribe_output(self._on_new_line))

    def _build(self) -> Gtk.Widget:
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

        for line in self._item.output_lines:
            self._buffer.insert(self._buffer.get_end_iter(), line)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_child(text_view)
        self._scroll = scroll

        GLib.idle_add(self._scroll_to_end)

        toolbar_view.set_content(scroll)
        return toolbar_view

    def _scroll_to_end(self):
        adj = self._scroll.get_vadjustment()
        adj.set_value(adj.get_upper() - adj.get_page_size())
        return GLib.SOURCE_REMOVE

    def _on_new_line(self, line: str):
        self._buffer.insert(self._buffer.get_end_iter(), line)
        adj = self._scroll.get_vadjustment()
        adj.set_value(adj.get_upper() - adj.get_page_size())


class PendingPage(Gtk.Box):

    def __init__(self, queue_service: InstallQueueService, push_fn):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self._queue_service = queue_service
        self._push_fn = push_fn
        self._subscribed_item_ids = set()

        self._stack = Gtk.Stack()
        self._stack.set_vexpand(True)
        self._stack.set_hexpand(True)

        empty_label = Gtk.Label(label=_("No pending installations"))
        empty_label.add_css_class("dim-label")
        self._stack.add_named(empty_label, "empty")

        self._list_box = Gtk.ListBox()
        self._list_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self._list_box.add_css_class("boxed-list")
        self._list_box.set_margin_top(12)
        self._list_box.set_margin_start(12)
        self._list_box.set_margin_end(12)
        self._list_box.set_margin_bottom(12)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(700)
        clamp.set_child(self._list_box)

        list_scroll = Gtk.ScrolledWindow()
        list_scroll.set_vexpand(True)
        list_scroll.set_hexpand(True)
        list_scroll.set_child(clamp)
        self._stack.add_named(list_scroll, "list")

        self.append(self._stack)

        self._rebuild()
        queue_service.subscribe_changes(self._rebuild)

    def _rebuild(self):
        child = self._list_box.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self._list_box.remove(child)
            child = next_child

        items = self._queue_service.get_all()

        if not items:
            self._stack.set_visible_child_name("empty")
            return

        self._stack.set_visible_child_name("list")

        for item in items:
            if id(item) not in self._subscribed_item_ids:
                self._subscribed_item_ids.add(id(item))
                item.subscribe_status(lambda _s: GLib.idle_add(self._rebuild))

            row = Adw.ActionRow()
            row.set_title(item.app_name)

            if item.status == "installing":
                spinner = Gtk.Spinner()
                spinner.set_spinning(True)
                spinner.set_valign(Gtk.Align.CENTER)
                row.add_suffix(spinner)
                row.set_subtitle(_("Installing…"))
            elif item.status == "done":
                icon = Gtk.Image.new_from_icon_name("object-select-symbolic")
                icon.set_valign(Gtk.Align.CENTER)
                row.add_suffix(icon)
                row.set_subtitle(_("Done"))
            elif item.status == "failed":
                icon = Gtk.Image.new_from_icon_name("dialog-error-symbolic")
                icon.set_valign(Gtk.Align.CENTER)
                row.add_suffix(icon)
                row.set_subtitle(_("Failed"))

            row.set_activatable(True)
            row.connect("activated", lambda _r, i=item: self._push_fn(PendingOutputPage(i)))
            self._list_box.append(row)
