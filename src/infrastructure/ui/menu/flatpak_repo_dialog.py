import threading

from domain.UseCase.add_new_remote_repo_uc import AddNewRemoteRepoUc
from domain.UseCase.delete_remote_repo_uc import DeleteRemoteRepoUc
from domain.UseCase.edit_remote_repo_uc import EditRemoteRepoUc
from domain.UseCase.update_database_from_api_uc import UpdateDatabaseFromApiUc
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.api.oci_api import OciApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw, GLib

from infrastructure.api.system_api import SystemApi
from infrastructure.repository.flatpakrepo_repository import FlatpakRepoRepository


class FlatpakRepoDialog(Adw.PreferencesDialog):

    def __init__(self):
        super().__init__()
        self.set_title(_("Flatpak repositories"))

        self._repo_repository = FlatpakRepoRepository()
        self._system_api = SystemApi()
        self._repo_rows = []

        page = Adw.PreferencesPage()
        self.add(page)

        self._list_group = Adw.PreferencesGroup()
        self._list_group.set_title(_("Configured repositories"))
        page.add(self._list_group)

        add_group = Adw.PreferencesGroup()
        add_group.set_title(_("Add a repository"))
        page.add(add_group)

        id_row = Adw.ActionRow(title=_("Repository name"))
        self._id_entry = Gtk.Entry()
        self._id_entry.set_placeholder_text("my-repo")
        self._id_entry.set_valign(Gtk.Align.CENTER)
        self._id_entry.set_hexpand(True)
        id_row.add_suffix(self._id_entry)
        add_group.add(id_row)

        url_row = Adw.ActionRow(title=_("Repository URL"))
        url_row.set_subtitle(
            _("For an OCI registry (e.g. Fedora), include the oci+ prefix: oci+https://registry.fedoraproject.org")
        )
        self._url_entry = Gtk.Entry()
        self._url_entry.set_placeholder_text("https://.../repo.flatpakrepo")
        self._url_entry.set_valign(Gtk.Align.CENTER)
        self._url_entry.set_hexpand(True)
        url_row.add_suffix(self._url_entry)
        add_group.add(url_row)

        self._scope_row = Adw.ComboRow()
        self._scope_row.set_title(_("Installation scope"))
        self._scope_row.set_model(Gtk.StringList.new(["user", "system"]))
        self._scope_row.set_selected(0)
        add_group.add(self._scope_row)

        self._add_btn = Gtk.Button(label=_("Add"))
        self._add_btn.add_css_class("suggested-action")
        self._add_btn.add_css_class("pill")
        self._add_btn.set_halign(Gtk.Align.CENTER)
        self._add_btn.set_margin_top(8)
        self._add_btn.set_margin_bottom(8)
        self._add_btn.connect("clicked", self._on_add)
        add_group.add(self._add_btn)

        self._refresh_list()

    def _set_add_busy(self, busy: bool):
        self._add_btn.set_sensitive(not busy)
        if busy:
            spinner = Adw.Spinner()
            spinner.set_size_request(16, 16)
            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            box.set_halign(Gtk.Align.CENTER)
            box.append(spinner)
            box.append(Gtk.Label(label=_("Please wait…")))
            self._add_btn.set_child(box)
        else:
            self._add_btn.set_child(None)
            self._add_btn.set_label(_("Add"))

    def _show_error_dialog(
        self,
        heading: str,
        error_message: str,
        fallback: str,
        suggested_url: str | None = None,
        on_accept_fix=None,
    ):
        message = error_message or fallback
        hint = self._get_error_hint(message)

        dialog = Adw.AlertDialog(heading=heading)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)

        message_label = Gtk.Label(label=message)
        message_label.set_wrap(True)
        message_label.set_selectable(True)
        message_label.set_xalign(0)
        box.append(message_label)

        if hint:
            hint_label = Gtk.Label(label=hint)
            hint_label.set_wrap(True)
            hint_label.set_selectable(True)
            hint_label.set_xalign(0)
            hint_label.add_css_class("dim-label")
            box.append(hint_label)

        dialog.set_extra_child(box)

        dialog.add_response("ok", _("OK"))
        dialog.set_default_response("ok")
        dialog.set_close_response("ok")

        if suggested_url and on_accept_fix:
            dialog.add_response("fix", _("Use {url}").format(url=suggested_url))
            dialog.set_response_appearance("fix", Adw.ResponseAppearance.SUGGESTED)
            dialog.set_default_response("fix")

            def on_response(_d, response):
                if response == "fix":
                    on_accept_fix(suggested_url)

            dialog.connect("response", on_response)

        dialog.present(self)

    @staticmethod
    def _get_error_hint(message: str) -> str:
        lowered = message.lower()
        if (
            "no summary found" in lowered
            or "unable to load summary" in lowered
            or "uri is not absolute" in lowered
        ):
            return _(
                "This usually means the repository URL is wrong or incomplete. "
                "For an OCI registry (e.g. Fedora), it must start with oci+https://, "
                "for example oci+https://registry.fedoraproject.org. "
                "Edit the repository and correct the URL, then try again."
            )
        if "404" in message:
            return _(
                "The URL could not be found (404). Double-check it points to a valid repository."
            )
        return ""

    @staticmethod
    def _suggest_corrected_url(url: str, error_message: str) -> str | None:
        lowered_error = error_message.lower()
        looks_like_bad_summary = (
            "no summary found" in lowered_error
            or "unable to load summary" in lowered_error
            or "uri is not absolute" in lowered_error
        )
        if not looks_like_bad_summary or not url:
            return None
        if url.startswith(("oci+http://", "oci+https://")):
            return None
        if url.startswith(("http://", "https://")):
            return "oci+" + url
        return "oci+https://" + url

    def _refresh_list(self):
        for row in self._repo_rows:
            self._list_group.remove(row)
        self._repo_rows = []

        for repo in self._repo_repository.get_all_entities():
            row = Adw.ActionRow(title=repo.getId(), subtitle=repo.getUrl())

            edit_btn = Gtk.Button()
            edit_btn.set_icon_name("document-edit-symbolic")
            edit_btn.set_valign(Gtk.Align.CENTER)
            edit_btn.add_css_class("flat")
            edit_btn.set_tooltip_text(_("Edit"))
            edit_btn.connect("clicked", self._on_edit_repo, repo)
            row.add_suffix(edit_btn)

            if repo.getId() != "flathub":
                delete_btn = Gtk.Button()
                delete_btn.set_icon_name("user-trash-symbolic")
                delete_btn.set_valign(Gtk.Align.CENTER)
                delete_btn.add_css_class("flat")
                delete_btn.add_css_class("error")
                delete_btn.set_tooltip_text(_("Delete"))
                delete_btn.connect("clicked", self._on_delete_repo, repo)
                row.add_suffix(delete_btn)

            self._list_group.add(row)
            self._repo_rows.append(row)

    def _on_delete_repo(self, _btn, repo):
        dialog = Adw.AlertDialog(
            heading=_("Delete repository"),
            body=_("Remove “{name}”? Apps installed from it will keep working, but you won't be able to install or update from this repository anymore.").format(name=repo.getId()),
        )
        dialog.add_response("cancel", _("Cancel"))
        dialog.add_response("delete", _("Delete"))
        dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_default_response("cancel")
        dialog.set_close_response("cancel")
        dialog.connect("response", self._on_delete_repo_response, repo)
        dialog.present(self)

    def _on_delete_repo_response(self, _dialog, response, repo):
        if response != "delete":
            return

        self.add_toast(Adw.Toast.new(_("Please wait…")))

        def run():
            success, error_message = DeleteRemoteRepoUc(
                FlatpakApi(), FlatpakRepoRepository(), AppstreamRepository()
            ).delete(repo.getId())
            GLib.idle_add(self._on_delete_done, success, error_message)

        threading.Thread(target=run, daemon=True).start()

    def _on_delete_done(self, success: bool, error_message: str):
        if success:
            self._refresh_list()
            self.add_toast(Adw.Toast.new(_("Repository deleted")))
        else:
            self._show_error_dialog(
                _("Couldn't delete repository"), error_message, _("Failed to delete repository")
            )

        return GLib.SOURCE_REMOVE

    def _on_edit_repo(self, _btn, repo):
        dialog = Adw.AlertDialog(heading=_("Edit repository"), body=repo.getId())

        url_entry = Gtk.Entry()
        url_entry.set_text(repo.getUrl())
        url_entry.set_hexpand(True)
        dialog.set_extra_child(url_entry)

        dialog.add_response("cancel", _("Cancel"))
        dialog.add_response("save", _("Save"))
        dialog.set_response_appearance("save", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("save")
        dialog.set_close_response("cancel")
        dialog.connect("response", self._on_edit_repo_response, repo, url_entry)
        dialog.present(self)

    def _on_edit_repo_response(self, _dialog, response, repo, url_entry):
        if response != "save":
            return

        new_url = url_entry.get_text().strip()
        if not new_url or new_url == repo.getUrl():
            return

        self._retry_edit(repo, new_url)

    def _retry_edit(self, repo, new_url: str):
        self.add_toast(Adw.Toast.new(_("Please wait…")))

        def run():
            success, error_message = EditRemoteRepoUc(
                FlatpakApi(), FlatpakRepoRepository()
            ).edit(repo.getId(), new_url)
            GLib.idle_add(self._on_edit_done, success, error_message, repo, new_url)

        threading.Thread(target=run, daemon=True).start()

    def _on_edit_done(self, success: bool, error_message: str, repo=None, attempted_url: str = ""):
        if success:
            self._refresh_list()
            self.add_toast(Adw.Toast.new(_("Repository updated")))
        else:
            fallback = _("Failed to update repository")
            suggested = self._suggest_corrected_url(attempted_url, error_message or fallback)
            self._show_error_dialog(
                _("Couldn't update repository"),
                error_message,
                fallback,
                suggested_url=suggested,
                on_accept_fix=lambda url: self._retry_edit(repo, url),
            )

        return GLib.SOURCE_REMOVE

    def _on_add(self, _btn):
        repo_id = self._id_entry.get_text().strip()
        url = self._url_entry.get_text().strip()

        if not repo_id or not url:
            self.add_toast(Adw.Toast.new(_("Name and URL are required")))
            return

        if self._repo_repository.exists(repo_id):
            self.add_toast(Adw.Toast.new(_("A repository with this name already exists")))
            return

        scope = "--user" if self._scope_row.get_selected() == 0 else "--system"

        self._set_add_busy(True)

        def run():
            success, error_message = AddNewRemoteRepoUc(FlatpakApi(),FlatpakRepoRepository()).add(repo_id,url,scope)
            GLib.idle_add(self._on_add_done, success, error_message)

        threading.Thread(target=run, daemon=True).start()

    def _on_add_done(self, success: bool, error_message: str):
        self._set_add_busy(False)

        if success:
            self._id_entry.set_text("")
            self._url_entry.set_text("")
            self._refresh_list()
            self.add_toast(Adw.Toast.new(_("Repository added")))

            # Enriching newly-discovered apps (OCI lookups included) can be
            # slow on a repo with hundreds of apps — keep it off the GTK
            # main thread so the dialog doesn't freeze.
            def sync():
                UpdateDatabaseFromApiUc(
                    FlathubApi(),
                    AppstreamRepository(),
                    SystemApi(),
                    ApiCacheRepository(),
                    FlatpakRepoRepository(),
                    FlatpakApi(),
                    "en",
                    OciApi(),
                ).process_for_other_repos()

            threading.Thread(target=sync, daemon=True).start()
        else:
            fallback = _("Failed to add repository")
            attempted_url = self._url_entry.get_text().strip()
            suggested = self._suggest_corrected_url(attempted_url, error_message or fallback)
            self._show_error_dialog(
                _("Couldn't add repository"),
                error_message,
                fallback,
                suggested_url=suggested,
                on_accept_fix=self._apply_url_fix_and_retry_add,
            )

        return GLib.SOURCE_REMOVE

    def _apply_url_fix_and_retry_add(self, url: str):
        self._url_entry.set_text(url)
        self._on_add(None)
