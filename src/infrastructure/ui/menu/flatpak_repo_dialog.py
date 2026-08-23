import threading

from domain.UseCase.add_new_remote_repo_uc import AddNewRemoteRepoUc
from domain.UseCase.update_database_from_api_uc import UpdateDatabaseFromApiUc
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.flatpak_api import FlatpakApi
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

    def _refresh_list(self):
        for row in self._repo_rows:
            self._list_group.remove(row)
        self._repo_rows = []

        for repo in self._repo_repository.get_all_entities():
            row = Adw.ActionRow(title=repo.getId(), subtitle=repo.getUrl())
            self._list_group.add(row)
            self._repo_rows.append(row)

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

        self._add_btn.set_sensitive(False)

        def run():
            success, error_message = AddNewRemoteRepoUc(FlatpakApi(),FlatpakRepoRepository()).add(repo_id,url,scope)
            GLib.idle_add(self._on_add_done, success, error_message)

        threading.Thread(target=run, daemon=True).start()

    def _on_add_done(self, success: bool, error_message: str):
        self._add_btn.set_sensitive(True)

        if success:
            self._id_entry.set_text("")
            self._url_entry.set_text("")
            self._refresh_list()
            self.add_toast(Adw.Toast.new(_("Repository added")))

            
            UpdateDatabaseFromApiUc(
                FlathubApi(), 
                AppstreamRepository(), 
                SystemApi(), 
                ApiCacheRepository(),
                FlatpakRepoRepository(),
                FlatpakApi(),
                "en"
            ).process_for_other_repos()
        else:
            message = error_message or _("Failed to add repository")
            toast = Adw.Toast.new(message)
            toast.set_timeout(0)
            self.add_toast(toast)

        return GLib.SOURCE_REMOVE
