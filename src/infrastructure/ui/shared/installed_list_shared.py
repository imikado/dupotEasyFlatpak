import subprocess
import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, GLib, Gtk, Pango

from domain.UseCase.get_recipe_content_uc import GetRecipeContentUc
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.repository.recipe_repository import RecipeRepository
from infrastructure.service.install_queue_service import InstallQueueService
from infrastructure.ui.appstream.downgrade_dialog import DowngradeDialog
from infrastructure.ui.appstream.install_dialog import InstallDialog


def _make_installed_row(
    app, on_click, is_user_installed: bool, has_recipe: bool, listbox: Gtk.ListBox
) -> Gtk.ListBoxRow:
    row = Gtk.ListBoxRow()
    row.set_activatable(False)

    # --- Left: icon + text (acts as nav button) ---
    icon = Gtk.Image.new_from_file(app.getIcon())
    icon.set_pixel_size(48)

    text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
    text_box.set_valign(Gtk.Align.CENTER)
    text_box.set_hexpand(True)

    title = Gtk.Label(label=app.getName())
    title.add_css_class("heading")
    title.set_halign(Gtk.Align.START)
    title.set_ellipsize(Pango.EllipsizeMode.END)
    title.set_max_width_chars(40)
    text_box.append(title)

    summary = Gtk.Label(label=app.getSummary())
    summary.set_halign(Gtk.Align.START)
    summary.add_css_class("caption")
    summary.add_css_class("dim-label")
    summary.set_ellipsize(Pango.EllipsizeMode.END)
    summary.set_max_width_chars(50)
    text_box.append(summary)

    info_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
    info_box.set_valign(Gtk.Align.CENTER)
    info_box.append(icon)
    info_box.append(text_box)

    nav_btn = Gtk.Button()
    nav_btn.set_child(info_box)
    nav_btn.add_css_class("flat")
    nav_btn.set_hexpand(True)
    nav_btn.connect("clicked", lambda _: on_click(nav_btn, app.id))

    # --- Right: action buttons ---
    btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
    btn_box.set_valign(Gtk.Align.CENTER)

    # Recipe overrides
    if has_recipe:
        recipe_btn = Gtk.Button(label=_("Recipe overrides"))

        def on_recipe(_btn):
            recipe_uc = GetRecipeContentUc(RecipeRepository())
            current_fs = FlatpakApi().get_override_filesystems(app.id)

            def on_confirm(_user_scope, active_permission_list):
                def run_overrides():
                    flatpak_api = FlatpakApi()
                    for perm, value in active_permission_list:
                        if perm.is_filesystem():
                            subprocess.run(
                                flatpak_api.get_override_filesystem_call(app.id, value)
                            )

                threading.Thread(target=run_overrides, daemon=True).start()

            dialog = InstallDialog(
                app.id,
                True,
                recipe_uc,
                on_confirm,
                heading=_("Recipe overrides"),
                confirm_label=_("Apply"),
                show_scope=False,
                filesystem_override_values=current_fs,
            )
            dialog.present(row.get_root())

        recipe_btn.connect("clicked", on_recipe)
        btn_box.append(recipe_btn)

    # Run
    run_btn = Gtk.Button(label=_("Run"))
    run_btn.add_css_class("suggested-action")
    run_btn.connect("clicked", lambda _: FlatpakApi().run_by_id(app.id))
    btn_box.append(run_btn)

    # Uninstall
    uninstall_btn = Gtk.Button(label=_("Uninstall"))
    uninstall_btn.add_css_class("destructive-action")
    # uninstall_btn.set_sensitive(is_user_installed)
    # if not is_user_installed:
    #    uninstall_btn.set_tooltip_text(_("System application cannot be uninstalled"))

    def on_uninstall(_btn):
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
            uninstall_btn.set_sensitive(False)
            uninstall_btn.set_label(_("Please wait…"))

            def run_uninstall():
                FlatpakApi().uninstall_by_id(
                    app.id, delete_data=delete_toggle.get_active()
                )
                result = FlatpakApi().get_info_by_id(app.id)
                if result.returncode != 0:  # non-zero = app no longer found = success
                    GLib.idle_add(lambda: listbox.remove(row))
                else:
                    GLib.idle_add(lambda: uninstall_btn.set_sensitive(True))
                    GLib.idle_add(lambda: uninstall_btn.set_label(_("Uninstall")))

            threading.Thread(target=run_uninstall, daemon=True).start()

        dialog.connect("response", on_response)
        dialog.present(row.get_root())

    uninstall_btn.connect("clicked", on_uninstall)
    btn_box.append(uninstall_btn)

    # Downgrade
    downgrade_btn = Gtk.Button(label=_("Downgrade"))

    def on_downgrade(_btn):
        downgrade_btn.set_sensitive(False)
        downgrade_btn.set_label(_("Loading…"))

        def fetch():
            api = FlatpakApi()
            history = api.get_history_list_by_id(app.id)
            current_commit = api.get_installed_commit_by_id(app.id)
            GLib.idle_add(on_history_loaded, history, current_commit)

        def on_history_loaded(history, current_commit):
            downgrade_btn.set_sensitive(True)
            downgrade_btn.set_label(_("Downgrade"))
            if not history:
                return

            def on_confirm(commit):
                scope = FlatpakApi().get_installation_scope(app.id)
                queue_item = InstallQueueService().enqueue(app.id, app.getName())

                def run():
                    process = subprocess.Popen(
                        FlatpakApi().get_downgrade_call(app.id, commit, f"--{scope}"),
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        text=True,
                    )
                    for line in process.stdout:
                        GLib.idle_add(queue_item.append_output, line)
                    process.wait()
                    GLib.idle_add(
                        queue_item.set_status,
                        "done" if process.returncode == 0 else "failed",
                    )

                threading.Thread(target=run, daemon=True).start()

            DowngradeDialog(history, on_confirm, current_commit).present(row.get_root())

        threading.Thread(target=fetch, daemon=True).start()

    downgrade_btn.connect("clicked", on_downgrade)
    btn_box.append(downgrade_btn)

    # --- Assemble row ---
    outer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
    outer.set_margin_top(4)
    outer.set_margin_bottom(4)
    outer.set_margin_start(4)
    outer.set_margin_end(8)
    outer.append(nav_btn)
    outer.append(btn_box)

    row.set_child(outer)
    return row


class InstalledListShared:

    def __init__(self):
        self._recipe_uc = GetRecipeContentUc(RecipeRepository())

        result = subprocess.run(
            FlatpakApi()._cmd("list", "--user", "--app", "--columns=application"),
            capture_output=True,
            text=True,
        )
        self._user_ids = {l.strip() for l in result.stdout.splitlines() if l.strip()}

        self._listbox = Gtk.ListBox()
        self._listbox.add_css_class("boxed-list")
        self._listbox.set_selection_mode(Gtk.SelectionMode.NONE)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        outer.set_margin_top(12)
        outer.set_margin_bottom(12)
        outer.set_margin_start(12)
        outer.set_margin_end(12)
        outer.append(self._listbox)
        self._widget = outer

    def get_widget(self) -> Gtk.Widget:
        return self._widget

    def append(self, app, on_click, *_on_click_args):
        is_user = app.id in self._user_ids
        has_recipe = self._recipe_uc.has_recipe(app.id)
        row = _make_installed_row(app, on_click, is_user, has_recipe, self._listbox)
        self._listbox.append(row)

    def clear(self):
        while child := self._listbox.get_first_child():
            self._listbox.remove(child)
