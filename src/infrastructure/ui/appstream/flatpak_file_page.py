import os
import subprocess
import tempfile
import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib, GdkPixbuf

from domain.entity.user_settings_entity import UserSettingsEntity
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.repository.local_apps_repository import LocalAppsRepository
from infrastructure.service.install_queue_service import InstallQueueService


class FlatpakFilePage(Adw.NavigationPage):

    def __init__(self, file_path: str, navigate_home_fn):
        super().__init__()
        self.set_title(_("Install .flatpak"))
        self._file_path = file_path
        self._navigate_home_fn = navigate_home_fn
        self._info = FlatpakApi().get_flatpak_bundle_info(file_path)
        self._temp_icon_path = None
        self.set_child(self._build())

    # ------------------------------------------------------------------ build

    def _build(self) -> Gtk.Widget:
        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(800)

        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        content_box.set_margin_top(24)
        content_box.set_margin_bottom(24)
        content_box.set_margin_start(16)
        content_box.set_margin_end(16)

        content_box.append(self._build_hero())
        content_box.append(self._build_details_group())
        content_box.append(self._build_install_group())
        content_box.append(self._build_install_button())

        clamp.set_child(content_box)
        scroll.set_child(clamp)
        toolbar_view.set_content(scroll)
        return toolbar_view

    # ------------------------------------------------------------------ hero

    def _build_hero(self) -> Gtk.Widget:
        hero = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        hero.set_valign(Gtk.Align.CENTER)

        # Icon
        icon_widget = self._make_icon_widget()
        hero.append(icon_widget)

        # Name + app-id
        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        text_box.set_valign(Gtk.Align.CENTER)

        app_id = self._info.get("name", os.path.basename(self._file_path))
        display_name = self._derive_display_name(app_id)

        name_label = Gtk.Label(label=display_name)
        name_label.add_css_class("title-1")
        name_label.set_halign(Gtk.Align.START)
        name_label.set_wrap(True)
        text_box.append(name_label)

        id_label = Gtk.Label(label=app_id)
        id_label.add_css_class("dim-label")
        id_label.set_halign(Gtk.Align.START)
        id_label.set_wrap(True)
        text_box.append(id_label)

        version = self._info.get("version", "")
        if version:
            ver_label = Gtk.Label(label=version)
            ver_label.add_css_class("caption")
            ver_label.set_halign(Gtk.Align.START)
            text_box.append(ver_label)

        hero.append(text_box)
        return hero

    def _make_icon_widget(self) -> Gtk.Widget:
        icon_bytes = self._info.get("icon")
        if icon_bytes:
            try:
                loader = GdkPixbuf.PixbufLoader.new_with_type("png")
                loader.write(icon_bytes)
                loader.close()
                pixbuf = loader.get_pixbuf()
                if pixbuf:
                    pixbuf = pixbuf.scale_simple(96, 96, GdkPixbuf.InterpType.BILINEAR)
                    img = Gtk.Image.new_from_pixbuf(pixbuf)
                    img.set_pixel_size(96)
                    return img
            except Exception:
                pass

        img = Gtk.Image.new_from_icon_name("package-x-generic")
        img.set_pixel_size(96)
        return img

    # ------------------------------------------------------------------ details group

    def _build_details_group(self) -> Gtk.Widget:
        group = Adw.PreferencesGroup()
        group.set_title(_("Details"))

        runtime = self._info.get("runtime", "")
        if runtime:
            row = Adw.ActionRow()
            row.set_title(_("Runtime"))
            row.set_subtitle(runtime)
            group.add(row)

        sdk = self._info.get("sdk", "")
        if sdk:
            row = Adw.ActionRow()
            row.set_title(_("SDK"))
            row.set_subtitle(sdk)
            group.add(row)

        origin = self._info.get("origin", "")
        if origin:
            row = Adw.ActionRow()
            row.set_title(_("Origin"))
            row.set_subtitle(origin)
            group.add(row)

        file_row = Adw.ActionRow()
        file_row.set_title(_("File"))
        file_row.set_subtitle(self._file_path)
        group.add(file_row)

        return group

    # ------------------------------------------------------------------ install scope group

    def _build_install_group(self) -> Gtk.Widget:
        group = Adw.PreferencesGroup()
        group.set_title(_("Installation"))

        self._user_scope_row = Adw.SwitchRow()
        self._user_scope_row.set_title(_("Install for current user only"))
        self._user_scope_row.set_active(UserSettingsEntity().is_user_scope())
        group.add(self._user_scope_row)

        return group

    # ------------------------------------------------------------------ install button

    def _build_install_button(self) -> Gtk.Widget:
        self._install_btn = Gtk.Button(label=_("Install"))
        self._install_btn.add_css_class("suggested-action")
        self._install_btn.add_css_class("pill")
        self._install_btn.set_halign(Gtk.Align.CENTER)
        self._install_btn.set_size_request(200, -1)
        self._install_btn.connect("clicked", self._on_install_clicked)
        return self._install_btn

    # ------------------------------------------------------------------ helpers

    @staticmethod
    def _derive_display_name(app_id: str) -> str:
        parts = app_id.split(".")
        if parts:
            return parts[-1]
        return app_id

    # ------------------------------------------------------------------ install

    def _on_install_clicked(self, _btn):
        self._install_btn.set_sensitive(False)
        self._install_btn.set_label(_("Please wait…"))

        app_id = self._info.get("name", os.path.basename(self._file_path))
        app_name = self._derive_display_name(app_id)
        user_scope = self._user_scope_row.get_active()
        flags = ["--user"] if user_scope else ["--system"]

        queue_item = InstallQueueService().enqueue(app_id, app_name, "user" if user_scope else "system")
        GLib.idle_add(self._navigate_home_fn)

        def _stream(cmd):
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            for line in process.stdout:
                GLib.idle_add(queue_item.append_output, line)
            process.wait()

        def run_install():
            flatpak_api = FlatpakApi()
            _stream(flatpak_api.get_install_bundle_call(self._file_path, *flags))
            result = flatpak_api.get_info_by_id(app_id)
            final_status = "done" if result.returncode == 0 else "failed"
            if final_status == "done":
                # Not in the Flathub appstream DB (installed from a local
                # bundle) — track it so the Installed page can still show
                # it. If a GitHub-flow entry already registered this app_id
                # (with its GitHub url), keep that url instead of wiping it.
                existing_local_app = LocalAppsRepository().get_by_id(app_id)
                url = existing_local_app.url if existing_local_app else ""
                version = self._info.get("version", "") or (
                    existing_local_app.version if existing_local_app else ""
                )
                LocalAppsRepository().insert_or_update(
                    app_id, app_name, url, version
                )
            GLib.idle_add(queue_item.set_status, final_status)

        threading.Thread(target=run_install, daemon=True).start()
