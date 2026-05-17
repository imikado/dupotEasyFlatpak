import subprocess
import threading
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.service.install_queue_service import InstallQueueService


class ToolsDialog(Adw.PreferencesDialog):

    def __init__(self, navigate_pending_fn):
        super().__init__()
        self.set_title(_("Tools"))

        self._flatpak_api = FlatpakApi()
        self._navigate_pending_fn = navigate_pending_fn

        page = Adw.PreferencesPage()
        self.add(page)

        cache_group = Adw.PreferencesGroup()
        cache_group.set_title(_("Cache management"))
        cache_group.set_description(
            _(
                "Sometimes you can have artifact in place of text displayed, clean the cache to fix it"
            )
        )
        page.add(cache_group)

        self._clear_btn = Gtk.Button(label=_("Clear cache"))
        self._clear_btn.add_css_class("pill")
        self._clear_btn.set_halign(Gtk.Align.CENTER)
        self._clear_btn.set_margin_top(8)
        self._clear_btn.set_margin_bottom(8)
        self._clear_btn.connect("clicked", self._on_clear_cache)
        cache_group.add(self._clear_btn)

        repair_group = Adw.PreferencesGroup()
        repair_group.set_title(_("Repair"))
        repair_group.set_description(
            _(
                "Fix icon/permission errors that can occur after installing apps (e.g. index.theme: Permission denied)"
            )
        )
        page.add(repair_group)

        self._repair_btn = Gtk.Button(label=_("Repair user installation"))
        self._repair_btn.add_css_class("pill")
        self._repair_btn.set_halign(Gtk.Align.CENTER)
        self._repair_btn.set_margin_top(8)
        self._repair_btn.set_margin_bottom(8)
        self._repair_btn.connect("clicked", self._on_repair)
        repair_group.add(self._repair_btn)

    def _run_command(self, app_id: str, app_name: str, cmd: list):
        queue_item = InstallQueueService().enqueue(app_id, app_name, show_output_default=True)
        self.force_close()
        GLib.idle_add(self._navigate_pending_fn)

        def run():
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            for line in process.stdout:
                GLib.idle_add(queue_item.append_output, line)
            process.wait()
            GLib.idle_add(queue_item.set_status, "done" if process.returncode == 0 else "failed")

        threading.Thread(target=run, daemon=True).start()

    def _on_clear_cache(self, _btn):
        self._run_command("cache", _("Cache clean"), self._flatpak_api.get_clean_cache_call())

    def _on_repair(self, _btn):
        self._run_command("repair", _("Flatpak repair"), self._flatpak_api.get_repair_user_call())
