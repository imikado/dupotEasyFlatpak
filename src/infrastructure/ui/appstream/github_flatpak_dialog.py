import os
import tempfile
import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, GLib, Gtk

from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.api.github_api import GithubApi
from infrastructure.repository.local_apps_repository import LocalAppsRepository


def _show_error(parent_widget, message: str):
    dialog = Adw.AlertDialog(heading=_("Error"), body=message)
    dialog.add_response("ok", _("OK"))
    dialog.present(parent_widget.get_root())


class GithubFlatpakUrlDialog(Adw.AlertDialog):
    """Step 1: ask for a GitHub project URL, look up its latest release."""

    def __init__(self, on_ready):
        super().__init__()
        self._on_ready = on_ready  # callable(owner, repo, release_info)

        self.set_heading(_("Install GitHub Flatpak"))
        self.set_body(
            _("Enter the URL of a GitHub project that publishes a .flatpak release asset.")
        )

        form_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        form_box.set_margin_top(8)
        form_box.set_size_request(500, -1)

        url_row = Adw.ActionRow(title=_("GitHub URL"))
        self._url_entry = Gtk.Entry()
        self._url_entry.set_valign(Gtk.Align.CENTER)
        self._url_entry.set_hexpand(True)
        self._url_entry.set_placeholder_text("https://github.com/owner/repo")
        url_row.add_suffix(self._url_entry)

        group = Adw.PreferencesGroup()
        group.add(url_row)
        form_box.append(group)

        self.set_extra_child(form_box)
        self.add_response("cancel", _("Cancel"))
        self.add_response("search", _("Find latest release"))
        self.set_response_appearance("search", Adw.ResponseAppearance.SUGGESTED)
        self.set_default_response("search")
        self.set_close_response("cancel")

        self.connect("response", self._on_response)

    def _on_response(self, _dialog, response):
        if response != "search":
            return

        url = self._url_entry.get_text().strip()
        github_api = GithubApi()
        parsed = github_api.parse_owner_repo(url)
        if not parsed:
            _show_error(
                self._url_entry,
                _("This doesn't look like a valid GitHub project URL."),
            )
            return

        owner, repo = parsed
        parent = self._url_entry.get_root()

        def fetch():
            release_info = github_api.get_latest_release_flatpak_asset(owner, repo)
            GLib.idle_add(self._on_fetched, owner, repo, release_info, parent)

        threading.Thread(target=fetch, daemon=True).start()

    def _on_fetched(self, owner, repo, release_info, parent):
        if not release_info:
            error_dialog = Adw.AlertDialog(
                heading=_("Error"),
                body=_(
                    "No release with a .flatpak asset was found for this project."
                ),
            )
            error_dialog.add_response("ok", _("OK"))
            error_dialog.present(parent)
            return GLib.SOURCE_REMOVE

        self._on_ready(owner, repo, release_info)
        return GLib.SOURCE_REMOVE


class GithubFlatpakConfirmDialog(Adw.AlertDialog):
    """Step 2: show the release found and confirm before downloading it."""

    def __init__(self, owner: str, repo: str, release_info: dict, on_confirm):
        super().__init__()
        self._on_confirm = on_confirm
        self._release_info = release_info

        self.set_heading(repo)
        self.set_body(
            _("Version {version} was found for {owner}/{repo}.").format(
                version=release_info["tag_name"], owner=owner, repo=repo
            )
        )

        group = Adw.PreferencesGroup()

        asset_row = Adw.ActionRow(title=_("Asset"))
        asset_row.set_subtitle(release_info["asset_name"])
        group.add(asset_row)

        version_row = Adw.ActionRow(title=_("Version"))
        version_row.set_subtitle(release_info["tag_name"])
        group.add(version_row)

        form_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        form_box.set_margin_top(8)
        form_box.append(group)
        self.set_extra_child(form_box)

        self.add_response("cancel", _("Cancel"))
        self.add_response("install", _("Install"))
        self.set_response_appearance("install", Adw.ResponseAppearance.SUGGESTED)
        self.set_default_response("install")
        self.set_close_response("cancel")

        self.connect("response", self._on_response)

    def _on_response(self, _dialog, response):
        if response == "install":
            self._on_confirm(self._release_info)


def open_github_flatpak_install_flow(parent_widget, on_open_flatpak_fn):
    """Entry point: wires the two-step dialog + download to the same
    on_open_flatpak callback used for installing a local .flatpak file
    (AppWindow.open_flatpak_file -> FlatpakFilePage)."""

    def on_ready(owner, repo, release_info):
        LocalAppsRepository().insert_or_update_deduped(
            f"{owner}/{repo}",
            repo,
            f"https://github.com/{owner}/{repo}",
            release_info["tag_name"],
        )

        def on_confirm(confirmed_release_info):
            download_and_open_install_page(
                parent_widget, owner, repo, confirmed_release_info, on_open_flatpak_fn
            )

        GithubFlatpakConfirmDialog(owner, repo, release_info, on_confirm).present(
            parent_widget.get_root()
        )

    GithubFlatpakUrlDialog(on_ready).present(parent_widget.get_root())


def download_and_open_install_page(
    parent_widget, owner, repo, release_info, on_open_flatpak_fn
):
    """Download a specific release's .flatpak asset and hand it to the
    existing local-.flatpak install page. Shared by the "install latest"
    flow and the release list on LocalAppDetailPage."""
    def run():
        # Keep the exact GitHub asset filename (shown in FlatpakFilePage's
        # "File" row and used as the app-id fallback) instead of a random
        # mkstemp hash — put it in its own temp dir to avoid collisions.
        tmp_dir = tempfile.mkdtemp()
        tmp_path = os.path.join(tmp_dir, release_info["asset_name"])

        ok = GithubApi().download_asset(release_info["download_url"], tmp_path)

        app_id = None
        if ok:
            # A non-empty download that isn't actually a valid flatpak
            # bundle (corrupt file, HTML error page, ...) must not be
            # allowed through to the install step either.
            bundle_info = FlatpakApi().get_flatpak_bundle_info(tmp_path)
            app_id = bundle_info.get("name")
            if not app_id:
                ok = False
            else:
                # Also register under the real flatpak app-id (distinct
                # from the "owner/repo" entry above) so the Installed page
                # can show this app even though it has no row in the
                # Flathub appstream DB.
                LocalAppsRepository().insert_or_update(
                    app_id,
                    repo,
                    f"https://github.com/{owner}/{repo}",
                    release_info["tag_name"],
                )

        def on_done():
            if not ok:
                _show_error(
                    parent_widget,
                    _("Failed to download a valid .flatpak file from this release."),
                )
                return
            on_open_flatpak_fn(tmp_path)

        GLib.idle_add(on_done)

    threading.Thread(target=run, daemon=True).start()
