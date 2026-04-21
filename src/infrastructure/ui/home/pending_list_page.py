import re
import threading
import time
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.service.install_queue_service import InstallQueueService, InstallQueueItem
from infrastructure.ui.shared.icons_shared import IconsShared

# Matches: "Updating 1/8...  [...]  44%  243.4 kB/s  00:54"
#          "Updating 1/8...  8%  101.4 kB/s"   (no ETA)
#          "Updating 1/8...  0%  0 bytes/s"     (bytes/s, no ETA)
#          "Installation...  44%  243.4 kB/s"
_PROGRESS_RE = re.compile(
    r'(\d+)%'                                       # percentage (required)
    r'(?:\s+([\d.]+\s*(?:[kMG]B|bytes)/s))?'        # speed (optional)
    r'(?:\s+(\d+:\d+))?'                            # ETA  (optional)
)
_ACTION_RE = re.compile(r'^([\w][\w\s]*?)(?:\s+(\d+)/(\d+))?\.\.\.')
_BRACKET_RE = re.compile(r'\[[^\]]*\]')


class PendingOutputPage(Adw.NavigationPage):

    def __init__(self, item: InstallQueueItem):
        super().__init__()
        self.set_title(item.app_name)
        self._item = item
        self._progress_bar = None
        self._action_label = None
        self._speed_label = None
        self._buffer = None
        self._scroll = None
        self._last_action: str | None = None
        self._pulse_source: int | None = None
        self.set_child(self._build())

        if item.external_pid is not None:
            self._start_pulse()
        else:
            for line in item.output_lines:
                self._dispatch_line(line)
            GLib.idle_add(self._scroll_to_end)
            item.subscribe_output(self._on_new_line)

        item.subscribe_status(lambda s: GLib.idle_add(self._on_status, s))
        self.connect("hidden", lambda _: (item.unsubscribe_output(self._on_new_line), self._stop_pulse()))

    def _build(self) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

        # Progress area
        progress_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        progress_box.set_margin_top(20)
        progress_box.set_margin_bottom(16)
        progress_box.set_margin_start(20)
        progress_box.set_margin_end(20)

        is_external = self._item.external_pid is not None
        initial_label = self._item.external_action.capitalize() + "…" if is_external and self._item.external_action else _("Installing…")

        self._action_label = Gtk.Label(label=initial_label)
        self._action_label.add_css_class("dim-label")
        self._action_label.set_halign(Gtk.Align.START)

        self._progress_bar = Gtk.ProgressBar()
        self._progress_bar.set_show_text(not is_external)
        self._progress_bar.set_hexpand(True)

        self._speed_label = Gtk.Label(label="")
        self._speed_label.add_css_class("caption")
        self._speed_label.add_css_class("dim-label")
        self._speed_label.set_halign(Gtk.Align.START)

        toggle_btn = Gtk.ToggleButton(label=_("Show output"))
        toggle_btn.add_css_class("flat")
        toggle_btn.add_css_class("caption")
        toggle_btn.set_halign(Gtk.Align.START)
        toggle_btn.set_active(False)
        toggle_btn.set_visible(not is_external)

        progress_box.append(self._action_label)
        progress_box.append(self._progress_bar)
        progress_box.append(self._speed_label)
        progress_box.append(toggle_btn)
        outer.append(progress_box)

        # Log area (non-progress lines only), hidden by default
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
        scroll.set_child(text_view)
        scroll.set_visible(False)
        self._scroll = scroll

        separator = Gtk.Separator()
        separator.set_visible(False)
        outer.append(separator)
        outer.append(scroll)

        def _on_toggle(btn):
            visible = btn.get_active()
            scroll.set_visible(visible)
            separator.set_visible(visible)
            btn.set_label(_("Hide output") if visible else _("Show output"))

        toggle_btn.connect("toggled", _on_toggle)

        toolbar_view.set_content(outer)
        return toolbar_view

    @staticmethod
    def _parse_action(clean: str) -> str | None:
        action_m = _ACTION_RE.match(clean)
        if not action_m:
            return None
        verb = action_m.group(1).strip()
        cur, total = action_m.group(2), action_m.group(3)
        return f"{verb} {cur}/{total}" if cur else verb

    def _dispatch_line(self, line: str):
        # \r is used by flatpak to overwrite progress; Python universal newlines
        # splits on \r, so a single "Updating 1/8...\r8% 101 kB/s" becomes two
        # separate lines. Strip \r artefacts and rejoin intent via _last_action.
        clean = _BRACKET_RE.sub("", line.replace("\r", "")).strip()
        if not clean:
            return

        m = _PROGRESS_RE.search(clean)
        if m:
            # Never override _last_action here: a combined "Installation... 71% ..."
            # line would clobber the more specific "Updating 1/8" set below.
            self._update_progress(
                int(m.group(1)) / 100.0,
                m.group(2),
                m.group(3),
                self._last_action,
            )
        elif _ACTION_RE.match(clean):
            # Pure action announcement ("Updating 1/8...") with no percentage yet —
            # store it so the next bare-percentage line can use it; skip the log.
            self._last_action = self._parse_action(clean)
        else:
            self._append_log(line)

    def _update_progress(self, pct: float, speed: str | None, eta: str | None, action: str | None):
        self._progress_bar.set_fraction(pct)
        if action:
            self._action_label.set_text(f"{action}…")
        parts = [p for p in (speed, eta) if p]
        self._speed_label.set_text("  ·  ".join(parts))

    def _append_log(self, line: str):
        self._buffer.insert(self._buffer.get_end_iter(), line)
        if self._scroll:
            adj = self._scroll.get_vadjustment()
            adj.set_value(adj.get_upper() - adj.get_page_size())

    def _start_pulse(self):
        def _pulse():
            self._progress_bar.pulse()
            return GLib.SOURCE_CONTINUE
        self._pulse_source = GLib.timeout_add(200, _pulse)

    def _stop_pulse(self):
        if self._pulse_source is not None:
            GLib.source_remove(self._pulse_source)
            self._pulse_source = None

    def _on_status(self, status: str):
        self._stop_pulse()
        if status == "done":
            self._progress_bar.set_fraction(1.0)
            self._progress_bar.set_show_text(True)
            self._action_label.set_text(_("Done"))
            self._speed_label.set_text("")
        elif status == "failed":
            self._progress_bar.set_show_text(True)
            self._action_label.set_text(_("Failed"))
            self._speed_label.set_text("")
        return GLib.SOURCE_REMOVE

    def _scroll_to_end(self):
        adj = self._scroll.get_vadjustment()
        adj.set_value(adj.get_upper() - adj.get_page_size())
        return GLib.SOURCE_REMOVE

    def _on_new_line(self, line: str):
        GLib.idle_add(self._dispatch_line, line)


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
        threading.Thread(target=self._detect_external, daemon=True).start()

    def _detect_external(self):
        api = FlatpakApi()
        for proc in api.get_running_flatpak_processes():
            pid = proc["pid"]
            app_id = proc["app_id"]
            app_name = app_id.split(".")[-1] if app_id else _("External process")
            item = self._queue_service.enqueue_external(pid, app_id, app_name, proc["action"])
            if item is not None:
                threading.Thread(
                    target=self._monitor_pid, args=(pid, item, api), daemon=True
                ).start()

    def _monitor_pid(self, pid: int, item: InstallQueueItem, api: FlatpakApi):
        while api.is_pid_running(pid):
            time.sleep(2)
        GLib.idle_add(item.set_status, "done")

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
            row.set_icon_name(IconsShared.ICON_PENDING)

            if item.status == "installing":
                spinner = Gtk.Spinner()
                spinner.set_spinning(True)
                spinner.set_valign(Gtk.Align.CENTER)
                row.add_suffix(spinner)
                row.set_subtitle(_("Installing…"))
            elif item.status == "done":
                icon = IconsShared().get_icon_by_name(IconsShared.ICON_CHECKMARK)
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
