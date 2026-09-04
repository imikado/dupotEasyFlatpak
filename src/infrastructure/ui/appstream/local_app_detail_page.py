import os
import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, GLib, Gtk

from domain.conf.path_conf import PathConf
from domain.entity.local_app_entity import LocalAppEntity
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.api.github_api import GithubApi
from infrastructure.repository.local_apps_repository import LocalAppsRepository
from infrastructure.ui.shared.icons_shared import IconsShared
from infrastructure.ui.appstream.github_flatpak_dialog import (
    _show_error,
    download_and_open_install_page,
)


class LocalAppDetailPage(Adw.NavigationPage):
    """Minimal detail page for apps installed from a local .flatpak file or a
    GitHub release — they have no row in the Flathub appstream DB, so this
    only shows what LocalAppsRepository tracked at install time."""

    RELEASES_PAGE_SIZE = 10

    def __init__(
        self,
        app_id: str,
        local_app: LocalAppEntity,
        on_uninstalled_fn=None,
        on_open_flatpak_fn=None,
    ):
        super().__init__()
        self._app_id = app_id
        self._local_app = local_app
        self._on_uninstalled_fn = on_uninstalled_fn
        self._on_open_flatpak_fn = on_open_flatpak_fn
        self.set_title(local_app.name or app_id)
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
        content_box.append(self._build_buttons())

        owner_repo = GithubApi().parse_owner_repo(self._local_app.url)
        if owner_repo:
            content_box.append(self._build_releases_group(*owner_repo))

        clamp.set_child(content_box)
        scroll.set_child(clamp)
        toolbar_view.set_content(scroll)
        return toolbar_view

    def _build_hero(self) -> Gtk.Widget:
        hero = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        hero.set_valign(Gtk.Align.CENTER)

        icon_path = f"{PathConf().get_icons_path()}/{self._app_id.lower()}.png"
        if os.path.isfile(icon_path):
            icon = Gtk.Image.new_from_file(icon_path)
            icon.set_pixel_size(96)
        else:
            icon = IconsShared.get_generic_app_icon(96)
        hero.append(icon)

        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        text_box.set_valign(Gtk.Align.CENTER)

        name_label = Gtk.Label(label=self._local_app.name or self._app_id)
        name_label.add_css_class("title-1")
        name_label.set_halign(Gtk.Align.START)
        name_label.set_wrap(True)
        text_box.append(name_label)

        id_label = Gtk.Label(label=self._app_id)
        id_label.add_css_class("dim-label")
        id_label.set_halign(Gtk.Align.START)
        id_label.set_wrap(True)
        text_box.append(id_label)

        if self._local_app.version:
            ver_label = Gtk.Label(label=self._local_app.version)
            ver_label.add_css_class("caption")
            ver_label.set_halign(Gtk.Align.START)
            text_box.append(ver_label)

        hero.append(text_box)
        return hero

    def _build_details_group(self) -> Gtk.Widget:
        group = Adw.PreferencesGroup()
        group.set_title(_("Details"))

        source_row = Adw.ActionRow()
        source_row.set_title(_("Source"))
        if self._local_app.url:
            source_row.set_subtitle(self._local_app.url)
            link_btn = Gtk.LinkButton(uri=self._local_app.url)
            link_btn.set_valign(Gtk.Align.CENTER)
            link_btn.set_child(Gtk.Image.new_from_icon_name("adw-external-link-symbolic"))
            source_row.add_suffix(link_btn)
        else:
            # Origin unknown — most likely this app's tracked info was lost
            # (e.g. local app data was reset) while the flatpak itself
            # stayed installed. Flatpak keeps no memory of a bundle's
            # original GitHub project, so offer to re-link it manually.
            source_row.set_subtitle(_("Unknown — no releases available"))
            link_btn = Gtk.Button(label=_("Link to GitHub project"))
            link_btn.set_valign(Gtk.Align.CENTER)
            link_btn.add_css_class("flat")
            link_btn.connect("clicked", self._on_link_github_clicked)
            source_row.add_suffix(link_btn)
        group.add(source_row)

        return group

    def _on_link_github_clicked(self, _btn):
        dialog = Adw.AlertDialog(heading=_("Link to GitHub project"))
        dialog.set_body(
            _("Enter the URL of the GitHub project this app was installed from.")
        )

        entry = Gtk.Entry()
        entry.set_placeholder_text("https://github.com/owner/repo")
        entry.set_hexpand(True)

        form_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        form_box.set_margin_top(8)
        form_box.set_size_request(400, -1)
        form_box.append(entry)
        dialog.set_extra_child(form_box)

        dialog.add_response("cancel", _("Cancel"))
        dialog.add_response("link", _("Link"))
        dialog.set_response_appearance("link", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("link")
        dialog.set_close_response("cancel")

        def on_response(_d, response):
            if response != "link":
                return
            url = entry.get_text().strip()
            if not GithubApi().parse_owner_repo(url):
                _show_error(
                    self,
                    _("This doesn't look like a valid GitHub project URL."),
                )
                return

            LocalAppsRepository().insert_or_update(
                self._app_id, self._local_app.name, url, self._local_app.version
            )
            self._local_app.url = url
            self.set_child(self._build())

        dialog.connect("response", on_response)
        dialog.present(self)

    def _build_releases_group(self, owner: str, repo: str) -> Gtk.Widget:
        self._releases_owner = owner
        self._releases_repo = repo
        self._releases_page = 0

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)

        self._releases_group = Adw.PreferencesGroup()
        self._releases_group.set_title(_("Releases"))
        outer.append(self._releases_group)

        self._load_more_btn = Gtk.Button(label=_("Load more releases"))
        self._load_more_btn.add_css_class("flat")
        self._load_more_btn.set_halign(Gtk.Align.CENTER)
        self._load_more_btn.set_visible(False)
        self._load_more_btn.connect("clicked", lambda _b: self._load_releases_page())
        outer.append(self._load_more_btn)

        self._loading_row = Adw.ActionRow(title=_("Loading…"))
        spinner = Gtk.Spinner()
        spinner.set_spinning(True)
        self._loading_row.add_suffix(spinner)
        self._releases_group.add(self._loading_row)

        self._load_releases_page()

        return outer

    def _load_releases_page(self):
        self._load_more_btn.set_sensitive(False)
        self._load_more_btn.set_label(_("Loading…"))

        owner = self._releases_owner
        repo = self._releases_repo
        next_page = self._releases_page + 1

        def fetch():
            releases = GithubApi().get_releases_with_flatpak_asset(
                owner, repo, self.RELEASES_PAGE_SIZE, next_page
            )
            GLib.idle_add(self._on_releases_page_loaded, owner, repo, releases)

        threading.Thread(target=fetch, daemon=True).start()

    def _on_releases_page_loaded(self, owner, repo, releases):
        if self._loading_row:
            self._releases_group.remove(self._loading_row)
            self._loading_row = None

        if self._releases_page == 0 and not releases:
            self._releases_group.add(
                Adw.ActionRow(title=_("No release with a .flatpak asset found"))
            )
            self._load_more_btn.set_visible(False)
            return GLib.SOURCE_REMOVE

        installed_tag = self._local_app.version

        for release_info in releases:
            is_installed = bool(installed_tag) and release_info["tag_name"] == installed_tag

            row = Adw.ExpanderRow(title=release_info["tag_name"])
            row.set_subtitle(release_info["summary"] or _("No description"))

            if is_installed:
                installed_badge = Gtk.Box(spacing=4, valign=Gtk.Align.CENTER)
                installed_badge.append(
                    Gtk.Image.new_from_icon_name("object-select-symbolic")
                )
                badge_label = Gtk.Label(label=_("Installed"))
                badge_label.add_css_class("success")
                installed_badge.append(badge_label)
                row.add_prefix(installed_badge)
                row.add_css_class("success")
                row.set_expanded(True)

            body = release_info.get("body", "").strip()
            body_label = Gtk.Label(label=body or _("No release notes."))
            body_label.set_halign(Gtk.Align.START)
            body_label.set_wrap(True)
            body_label.set_selectable(True)
            if not body:
                body_label.add_css_class("dim-label")
            body_label.set_margin_top(4)
            body_label.set_margin_bottom(12)
            body_label.set_margin_start(12)
            body_label.set_margin_end(12)
            row.add_row(body_label)

            if self._on_open_flatpak_fn:
                install_btn = Gtk.Button(
                    label=_("Reinstall") if is_installed else _("Install")
                )
                install_btn.set_valign(Gtk.Align.CENTER)
                install_btn.add_css_class("flat")
                install_btn.connect(
                    "clicked",
                    lambda _b, ri=release_info: download_and_open_install_page(
                        self, owner, repo, ri, self._on_open_flatpak_fn
                    ),
                )
                row.add_suffix(install_btn)

            self._releases_group.add(row)

        self._releases_page += 1
        self._load_more_btn.set_sensitive(True)
        self._load_more_btn.set_label(_("Load more releases"))
        self._load_more_btn.set_visible(len(releases) >= self.RELEASES_PAGE_SIZE)

        return GLib.SOURCE_REMOVE

    def _build_buttons(self) -> Gtk.Widget:
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        btn_box.set_halign(Gtk.Align.CENTER)

        run_btn = Gtk.Button(label=_("Run"))
        run_btn.add_css_class("suggested-action")
        run_btn.add_css_class("pill")
        run_btn.connect("clicked", lambda _: FlatpakApi().run_by_id(self._app_id))
        btn_box.append(run_btn)

        self._uninstall_btn = Gtk.Button(label=_("Uninstall"))
        self._uninstall_btn.add_css_class("destructive-action")
        self._uninstall_btn.add_css_class("pill")
        self._uninstall_btn.connect("clicked", self._on_uninstall_clicked)
        btn_box.append(self._uninstall_btn)

        return btn_box

    # ------------------------------------------------------------------ uninstall

    def _on_uninstall_clicked(self, _btn):
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
        dialog.set_response_appearance("confirm", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_default_response("cancel")
        dialog.set_close_response("cancel")

        def on_response(_d, response):
            if response != "confirm":
                return
            self._uninstall_btn.set_sensitive(False)
            self._uninstall_btn.set_label(_("Please wait…"))

            def run_uninstall():
                flatpak_api = FlatpakApi()
                flatpak_api.uninstall_by_id(
                    self._app_id, delete_data=delete_toggle.get_active()
                )
                result = flatpak_api.get_info_by_id(self._app_id)
                if result.returncode != 0:  # non-zero = no longer found = success
                    LocalAppsRepository().delete(self._app_id)
                    GLib.idle_add(self._on_uninstall_done)
                else:
                    GLib.idle_add(self._uninstall_btn.set_sensitive, True)
                    GLib.idle_add(self._uninstall_btn.set_label, _("Uninstall"))

            threading.Thread(target=run_uninstall, daemon=True).start()

        dialog.connect("response", on_response)
        dialog.present(self)

    def _on_uninstall_done(self):
        if self._on_uninstalled_fn:
            self._on_uninstalled_fn()
        self._navigate_home()
        return GLib.SOURCE_REMOVE

    def _navigate_home(self):
        nav = self.get_parent()
        if isinstance(nav, Adw.NavigationView):
            stack = nav.get_navigation_stack()
            if stack.get_n_items() > 1:
                nav.pop_to_page(stack.get_item(0))
