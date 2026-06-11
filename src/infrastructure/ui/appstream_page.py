import re
import subprocess
import threading
import urllib.request
from domain.UseCase.get_recipe_content_uc import GetRecipeContentUc
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.recipe_repository import RecipeRepository

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib, Gdk, Gio

import domain.conf.app_state as app_state
from domain.entity.appstream_long_entity import AppstreamLongEntity
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.service.install_queue_service import InstallQueueService
from infrastructure.ui.shared.icons_shared import IconsShared
from infrastructure.ui.appstream.downgrade_dialog import DowngradeDialog
from infrastructure.ui.appstream.install_dialog import InstallDialog


def _webp_to_png(data: bytes) -> bytes:
    from gi.repository import GdkPixbuf

    loader = GdkPixbuf.PixbufLoader.new()
    loader.write(data)
    loader.close()
    pixbuf = loader.get_pixbuf()
    ok, png_bytes = pixbuf.save_to_bufferv("png", [], [])
    if not ok:
        raise RuntimeError("GdkPixbuf failed to encode PNG")
    return bytes(png_bytes)


class AppstreamPage(Adw.NavigationPage):

    _get_recipe_content: GetRecipeContentUc

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

        if app.should_update(SystemApi().get_datetime_current_timestamp()):

            def _fetch_and_update():
                try:
                    raw_obj = FlathubApi().get_appstream_by_id(app.id)
                    AppstreamRepository().update_from_raw_object_with_id(
                        app.id, raw_obj
                    )
                    refreshed = AppstreamRepository().get_by_id(app.id)
                    if refreshed:
                        GLib.idle_add(lambda: self._refresh(refreshed))
                except Exception as e:
                    print(f"[appstream update] ERROR: {e}")

            threading.Thread(target=_fetch_and_update, daemon=True).start()

        self._get_recipe_content = GetRecipeContentUc(RecipeRepository())

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

            check = IconsShared().get_icon_by_name(IconsShared.ICON_CHECKMARK)
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

        has_recipe = self._get_recipe_content.has_recipe(app.id)

        install_btn = Gtk.Button()
        install_btn.set_sensitive(False)

        recipe_btn = Gtk.Button()
        recipe_btn.set_label(_("Recipe overrides"))
        recipe_btn.set_visible(False)
        recipe_btn.connect("clicked", self._on_recipe_overrides_clicked, app.id)

        downgrade_btn = Gtk.Button()
        downgrade_btn.set_label(_("Downgrade"))
        downgrade_btn.set_visible(False)
        downgrade_btn.connect("clicked", self._on_downgrade_clicked, app.id, app.name)

        run_btn = Gtk.Button()
        run_btn.set_label(_("Run"))
        run_btn.set_visible(False)
        run_btn.add_css_class("suggested-action")
        run_btn.connect("clicked", lambda _btn: FlatpakApi().run_by_id(app.id))

        install_btn.connect(
            "clicked",
            self._on_install_clicked,
            recipe_btn,
            downgrade_btn,
            run_btn,
            app.id,
            app.name,
            has_recipe,
        )

        btn_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        btn_row.set_halign(Gtk.Align.CENTER)
        btn_row.set_margin_top(8)
        btn_row.append(run_btn)
        btn_row.append(install_btn)
        btn_row.append(recipe_btn)
        btn_row.append(downgrade_btn)
        info_box.append(btn_row)

        self._check_install_state(
            install_btn, recipe_btn, downgrade_btn, run_btn, app.id, has_recipe
        )

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

        if app.get_arche_list():
            row = Adw.ActionRow()
            row.set_title(_("Architectures"))
            row.set_subtitle(app.get_arche_label())
            details_group.add(row)

        if app.has_url_homepage():
            url = app.get_url_homepage()
            row = Adw.ActionRow()
            row.set_title(_("Homepage"))
            icon = IconsShared().get_icon_by_name(IconsShared.ICON_HOMEPAGE)
            icon.set_valign(Gtk.Align.CENTER)
            row.add_prefix(icon)
            arrow = Gtk.Image.new_from_icon_name("go-next-symbolic")
            arrow.set_valign(Gtk.Align.CENTER)
            row.add_suffix(arrow)
            row.set_activatable(True)
            row.connect("activated", lambda _r, u=url: Gio.AppInfo.launch_default_for_uri(u, None))
            details_group.add(row)

        if app.has_url_bugtracker():
            url = app.get_url_bugtracker()
            row = Adw.ActionRow()
            row.set_title(_("Bug Tracker"))
            icon = IconsShared().get_icon_by_name(IconsShared.ICON_BUGTRACKER)
            icon.set_valign(Gtk.Align.CENTER)
            row.add_prefix(icon)
            arrow = Gtk.Image.new_from_icon_name("go-next-symbolic")
            arrow.set_valign(Gtk.Align.CENTER)
            row.add_suffix(arrow)
            row.set_activatable(True)
            row.connect("activated", lambda _r, u=url: Gio.AppInfo.launch_default_for_uri(u, None))
            details_group.add(row)

        if app.has_url_donation():
            url = app.get_url_bdonation()
            row = Adw.ActionRow()
            row.set_title(_("Donate"))
            icon = IconsShared().get_icon_by_name(IconsShared.ICON_DONATION)
            icon.set_valign(Gtk.Align.CENTER)
            row.add_prefix(icon)
            arrow = Gtk.Image.new_from_icon_name("go-next-symbolic")
            arrow.set_valign(Gtk.Align.CENTER)
            row.add_suffix(arrow)
            row.set_activatable(True)
            row.connect("activated", lambda _r, u=url: Gio.AppInfo.launch_default_for_uri(u, None))
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

        releases_widget = self._build_releases_section(app)
        if releases_widget:
            details_clamp_box.append(releases_widget)

        page_box.append(details_clamp)

        self._screenshot_overlay_host = Gtk.Overlay()
        self._screenshot_overlay_host.set_child(outer_scroll)
        toolbar_view.set_content(self._screenshot_overlay_host)

        return toolbar_view

    def _navigate_home(self):
        nav = self.get_parent()
        if isinstance(nav, Adw.NavigationView):
            stack = nav.get_navigation_stack()
            if stack.get_n_items() > 1:
                nav.pop_to_page(stack.get_item(0))
        return GLib.SOURCE_REMOVE

    def _check_install_state(
        self,
        btn: Gtk.Button,
        recipe_btn: Gtk.Button,
        downgrade_btn: Gtk.Button,
        run_btn: Gtk.Button,
        app_id: str,
        has_recipe: bool,
    ):
        def check():
            installed = FlatpakApi().is_app_id_installed(app_id)
            GLib.idle_add(
                self._apply_install_state,
                btn,
                recipe_btn,
                downgrade_btn,
                run_btn,
                installed,
                has_recipe,
            )

        threading.Thread(target=check, daemon=True).start()

    def _apply_install_state(
        self,
        btn: Gtk.Button,
        recipe_btn: Gtk.Button,
        downgrade_btn: Gtk.Button,
        run_btn: Gtk.Button,
        installed: bool,
        has_recipe: bool,
    ):
        btn.set_sensitive(True)
        if installed:
            btn.set_label(_("Uninstall"))
            btn.remove_css_class("suggested-action")
            btn.add_css_class("destructive-action")
            recipe_btn.set_visible(has_recipe)
            downgrade_btn.set_visible(True)
            run_btn.set_visible(True)
        else:
            if has_recipe:
                btn_label = _("Install with recipe")
            else:
                btn_label = _("Install")
            btn.set_label(btn_label)
            btn.remove_css_class("destructive-action")
            btn.add_css_class("suggested-action")
            recipe_btn.set_visible(False)
            downgrade_btn.set_visible(False)
            run_btn.set_visible(False)

    def _on_install_clicked(
        self,
        btn: Gtk.Button,
        recipe_btn: Gtk.Button,
        downgrade_btn: Gtk.Button,
        run_btn: Gtk.Button,
        app_id: str,
        app_name: str,
        has_recipe: bool,
    ):
        installed = btn.has_css_class("destructive-action")

        if installed:
            delete_toggle = Gtk.Switch()
            delete_toggle.set_active(False)
            delete_toggle.set_valign(Gtk.Align.CENTER)

            toggle_row = Adw.ActionRow()
            toggle_row.set_title(_("Delete application data"))
            toggle_row.add_suffix(delete_toggle)
            toggle_row.set_activatable_widget(delete_toggle)

            group = Adw.PreferencesGroup()
            group.add(toggle_row)

            dialog = Adw.AlertDialog(heading=_("Uninstall"))
            dialog.set_extra_child(group)
            dialog.add_response("cancel", _("Cancel"))
            dialog.add_response("confirm", _("Uninstall"))
            dialog.set_response_appearance(
                "confirm", Adw.ResponseAppearance.DESTRUCTIVE
            )
            dialog.set_default_response("cancel")
            dialog.set_close_response("cancel")

            def on_response(_d, response):
                if response != "confirm":
                    return
                btn.set_sensitive(False)
                btn.set_label(_("Please wait…"))

                def run_uninstall():
                    flatpak_api = FlatpakApi()
                    flatpak_api.uninstall_by_id(
                        app_id, delete_data=delete_toggle.get_active()
                    )
                    app_state.needs_updates_refresh = True
                    result = flatpak_api.get_info_by_id(app_id)
                    GLib.idle_add(
                        self._apply_install_state,
                        btn,
                        recipe_btn,
                        downgrade_btn,
                        run_btn,
                        result.returncode == 0,
                        has_recipe,
                    )

                threading.Thread(target=run_uninstall, daemon=True).start()

            dialog.connect("response", on_response)
            dialog.present(self)
            return

        # --- Install: show confirm dialog ---
        def on_confirm(user_scope, active_permission_list):
            btn.set_sensitive(False)
            btn.set_label(_("Please wait…"))

            queue_item = InstallQueueService().enqueue(app_id, app_name)
            GLib.idle_add(self._navigate_home)

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
                flags = ["--user"] if user_scope else ["--system"]
                _stream(flatpak_api.get_install_call(app_id, *flags))
                for perm, value in active_permission_list:
                    if perm.is_filesystem():
                        _stream(flatpak_api.get_override_filesystem_call(app_id, value))
                    elif perm.is_install_flatpak_yes_no():
                        _stream(flatpak_api.get_install_call(perm.get_value(), *flags))
                result = flatpak_api.get_info_by_id(app_id)
                final_status = "done" if result.returncode == 0 else "failed"
                GLib.idle_add(queue_item.set_status, final_status)
                GLib.idle_add(
                    self._apply_install_state,
                    btn,
                    recipe_btn,
                    downgrade_btn,
                    run_btn,
                    result.returncode == 0,
                    has_recipe,
                )

            threading.Thread(target=run_install, daemon=True).start()

        dialog = InstallDialog(app_id, has_recipe, self._get_recipe_content, on_confirm)
        dialog.present(self)

    def _on_downgrade_clicked(self, btn: Gtk.Button, app_id: str, app_name: str):
        old_label_widget = btn.get_child()

        # 2. Create the Overlay and the Spinner
        overlay = Gtk.Overlay()
        spinner = Gtk.Spinner()
        spinner.start()

        # 3. Transfer the label to the overlay
        # We remove it from the button so we can add it to the overlay
        btn.set_child(None)
        overlay.set_child(old_label_widget)  # The label is now the base layer
        overlay.add_overlay(spinner)  # The spinner floats on top

        # 4. Set the overlay as the new button content
        btn.set_child(overlay)
        btn.set_sensitive(False)
        old_label_widget.set_opacity(0.3)

        def fetch():
            api = FlatpakApi()
            history = api.get_history_list_by_id(app_id)
            current_commit = api.get_installed_commit_by_id(app_id)
            GLib.idle_add(on_history_loaded, history, current_commit)

        def on_history_loaded(history, current_commit):
            # btn.set_label(_("Downgrade"))
            spinner.stop()
            old_label_widget.set_opacity(1.0)
            btn.set_sensitive(True)

            # btn.label.set_opacity(1.0)
            if not history:
                return

            def on_confirm(commit):
                scope = FlatpakApi().get_installation_scope(app_id)
                flags = [f"--{scope}"]
                queue_item = InstallQueueService().enqueue(app_id, app_name)
                GLib.idle_add(self._navigate_home)

                def run():
                    process = subprocess.Popen(
                        FlatpakApi().get_downgrade_call(app_id, commit, *flags),
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        text=True,
                    )
                    for line in process.stdout:
                        GLib.idle_add(queue_item.append_output, line)
                    process.wait()
                    final_status = "done" if process.returncode == 0 else "failed"
                    GLib.idle_add(queue_item.set_status, final_status)

                threading.Thread(target=run, daemon=True).start()

            DowngradeDialog(history, on_confirm, current_commit).present(self)

        threading.Thread(target=fetch, daemon=True).start()

    def _on_recipe_overrides_clicked(self, _btn: Gtk.Button, app_id: str):
        current_fs = FlatpakApi().get_override_filesystems(app_id)

        def on_confirm(_user_scope, active_permission_list):
            def run_overrides():
                flatpak_api = FlatpakApi()
                for perm, value in active_permission_list:
                    if perm.is_filesystem():
                        subprocess.run(
                            flatpak_api.get_override_filesystem_call(app_id, value)
                        )

            threading.Thread(target=run_overrides, daemon=True).start()

        dialog = InstallDialog(
            app_id,
            True,
            self._get_recipe_content,
            on_confirm,
            heading=_("Recipe overrides"),
            confirm_label=_("Apply"),
            show_scope=False,
            filesystem_override_values=current_fs,
        )
        dialog.present(self)

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
        hbox.set_halign(Gtk.Align.CENTER)
        hbox.set_margin_top(8)
        hbox.set_margin_bottom(8)
        hbox.set_margin_start(8)
        hbox.set_margin_end(8)

        large_urls = [s.large for s in screenshots]
        for idx, screenshot in enumerate(screenshots):
            btn = Gtk.Button()
            btn.add_css_class("card")

            picture = Gtk.Picture()
            picture.set_size_request(360, 210)
            btn.set_child(picture)

            self._load_image_async(picture, screenshot.preview)
            btn.connect("clicked", self._on_screenshot_clicked, large_urls, idx)
            hbox.append(btn)

        scroll.set_child(hbox)
        section_box.append(scroll)

        return section_box

    def _load_image_async(self, picture: Gtk.Picture, url: str):
        def fetch():
            try:
                data = urllib.request.urlopen(url).read()
                png_bytes = _webp_to_png(data)

                def apply():
                    texture = Gdk.Texture.new_from_bytes(GLib.Bytes.new(png_bytes))
                    picture.set_paintable(texture)

                GLib.idle_add(apply)
            except Exception as e:
                import traceback

                print(f"[img] ERROR: {e}")
                traceback.print_exc()

        threading.Thread(target=fetch, daemon=True).start()

    def _on_screenshot_clicked(self, _btn, urls: list, index: int):
        state = {"index": index}

        # Dark backdrop — clicking it closes the viewer
        backdrop = Gtk.Box()
        backdrop.set_hexpand(True)
        backdrop.set_vexpand(True)
        backdrop_css = Gtk.CssProvider()
        backdrop_css.load_from_string(
            ".ss-backdrop { background-color: rgba(0,0,0,0.85); }"
        )
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            backdrop_css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        backdrop.add_css_class("ss-backdrop")

        viewer_overlay = Gtk.Overlay()
        viewer_overlay.set_hexpand(True)
        viewer_overlay.set_vexpand(True)
        viewer_overlay.set_focusable(True)
        viewer_overlay.set_child(backdrop)

        def close_viewer():
            self._screenshot_overlay_host.remove_overlay(viewer_overlay)

        backdrop_gesture = Gtk.GestureClick()
        backdrop_gesture.connect("pressed", lambda *_: close_viewer())
        backdrop.add_controller(backdrop_gesture)

        key_ctrl = Gtk.EventControllerKey()

        def on_key(_ctrl, keyval, _keycode, _mod):
            if keyval == Gdk.KEY_Escape:
                close_viewer()
                return True
            return False

        key_ctrl.connect("key-pressed", on_key)
        viewer_overlay.add_controller(key_ctrl)

        # Centered content card
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        content_box.set_halign(Gtk.Align.CENTER)
        content_box.set_valign(Gtk.Align.CENTER)
        content_box.set_size_request(900, 600)

        picture = Gtk.Picture()
        picture.set_content_fit(Gtk.ContentFit.CONTAIN)
        picture.set_vexpand(True)
        picture.set_hexpand(True)

        spinner = Gtk.Spinner()
        spinner.set_spinning(True)
        spinner.set_halign(Gtk.Align.CENTER)
        spinner.set_valign(Gtk.Align.CENTER)

        prev_btn = Gtk.Button.new_from_icon_name("go-previous-symbolic")
        prev_btn.add_css_class("circular")
        prev_btn.add_css_class("osd")
        prev_btn.set_valign(Gtk.Align.CENTER)
        prev_btn.set_halign(Gtk.Align.START)
        prev_btn.set_margin_start(12)
        prev_btn.set_visible(len(urls) > 1)

        next_btn = Gtk.Button.new_from_icon_name("go-next-symbolic")
        next_btn.add_css_class("circular")
        next_btn.add_css_class("osd")
        next_btn.set_valign(Gtk.Align.CENTER)
        next_btn.set_halign(Gtk.Align.END)
        next_btn.set_margin_end(12)
        next_btn.set_visible(len(urls) > 1)

        inner_overlay = Gtk.Overlay()
        inner_overlay.set_vexpand(True)
        inner_overlay.set_hexpand(True)
        inner_overlay.set_child(picture)
        inner_overlay.add_overlay(spinner)
        inner_overlay.add_overlay(prev_btn)
        inner_overlay.add_overlay(next_btn)
        content_box.append(inner_overlay)

        viewer_overlay.add_overlay(content_box)

        def load_image(url):
            spinner.set_visible(True)
            spinner.set_spinning(True)
            picture.set_paintable(None)

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

        def on_prev(_btn):
            state["index"] = (state["index"] - 1) % len(urls)
            load_image(urls[state["index"]])

        def on_next(_btn):
            state["index"] = (state["index"] + 1) % len(urls)
            load_image(urls[state["index"]])

        prev_btn.connect("clicked", on_prev)
        next_btn.connect("clicked", on_next)

        self._screenshot_overlay_host.add_overlay(viewer_overlay)
        viewer_overlay.grab_focus()
        load_image(urls[index])

    def _refresh(self, app: AppstreamLongEntity):
        self.set_title(app.name)
        self.set_child(self._build(app))
        return GLib.SOURCE_REMOVE

    def _build_releases_section(self, app: AppstreamLongEntity):
        try:
            releases = app.get_release_list()
        except Exception:
            return None

        if not releases:
            return None

        group = Adw.PreferencesGroup()
        group.set_title(_("Release History"))

        for release in releases[:10]:
            row = Adw.ActionRow()
            row.set_title(release.version)
            row.set_subtitle(release.datetime)
            group.add(row)

        return group
