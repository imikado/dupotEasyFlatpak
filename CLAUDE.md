# dupotEasyFlatpak — AI context

## Mode de réponse

`token-optimizer` skill must be invoked at the start of every conversation on this project, without waiting for an explicit request — see `.claude/skills/token-optimizer/SKILL.md`.

## Translations workflow

Languages: `ar de es fr it pt_BR ro` — .po files live in `src/infrastructure/locales/<lang>/LC_MESSAGES/Easy_flatpak.po`.

1. After adding new `_("…")` strings in Python code, run:
   ```
   ./generate_translations.sh   # extracts strings → .pot, merges into .po, compiles .mo
   ```
2. To fill in missing translations: ask Claude Code to "generate missing translations".
   Claude reads the untranslated strings directly from the .po files (via `msgattrib --untranslated`),
   translates them inline for all 6 languages, applies them with the regex replacer in `translate_missing.py`,
   and recompiles the .mo files — no API key needed.

## Stack
- Python, GTK4 + libadwaita (`Adw`), Flatpak
- Entry point: `src/main.py` — installs `_()` into builtins via `en_i18n.install()`. All linter warnings about `_` being undefined are **false positives**.
- UI lives under `src/infrastructure/ui/`
- Domain logic under `src/domain/`
- External process calls under `src/infrastructure/api/flatpak_api.py`

## Key pattern: running a command and showing it in the Pending page

This is the standard pattern for any long-running shell command (install, repair, cache clean, etc.).

### 1. Add a method to `FlatpakApi` that returns the command list

```python
# src/infrastructure/api/flatpak_api.py
def get_repair_user_call(self) -> list:
    return self._cmd("repair", "--user")
```

`_cmd()` automatically prepends `["flatpak-spawn", "--host", "--directory=/"]` when the app itself runs as a Flatpak (`FLATPAK_ID` env var is set), so all commands transparently escape the sandbox.

### 2. Enqueue an item and stream output to it

```python
import subprocess
import threading
from gi.repository import GLib
from infrastructure.api.flatpak_api import FlatpakApi
from infrastructure.service.install_queue_service import InstallQueueService

queue_item = InstallQueueService().enqueue(
    app_id,        # arbitrary string key, e.g. "repair"
    app_name,      # display name shown in the Pending tab
    show_output_default=True,   # skips progress bar, shows log immediately
)
# Navigate to the pending page BEFORE starting the thread
GLib.idle_add(navigate_pending_fn)

def run():
    process = subprocess.Popen(
        FlatpakApi().get_repair_user_call(),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    for line in process.stdout:
        GLib.idle_add(queue_item.append_output, line)
    process.wait()
    GLib.idle_add(queue_item.set_status, "done" if process.returncode == 0 else "failed")

threading.Thread(target=run, daemon=True).start()
```

### 3. Navigate to the Pending tab

`InstallQueueService` is a **singleton**. Enqueuing automatically makes the Pending tab visible (wired in `app_window.py` via `subscribe_changes`). To jump there immediately:

```python
# In app_window.py — saved as self._view_stack and passed as navigate_pending_fn
def _navigate_to_pending(self):
    stack = self.navigation_view.get_navigation_stack()
    if stack.get_n_items() > 1:
        self.navigation_view.pop_to_page(stack.get_item(0))
    if hasattr(self, "_view_stack"):
        self._view_stack.set_visible_child_name("pending")
```

Pass `self._navigate_to_pending` as a callback wherever needed (e.g. to dialogs).

### `InstallQueueItem` fields

| Field | Default | Purpose |
|---|---|---|
| `app_id` | required | Key string (e.g. `"com.example.App"` or `"repair"`) |
| `app_name` | required | Label shown in the Pending list row |
| `scope` | `"user"` | Install scope |
| `status` | `"installing"` | `"installing"` → `"done"` or `"failed"` |
| `external_pid` | `None` | Set by `enqueue_external()` for processes started outside this app |
| `show_output_default` | `False` | When `True`: hides progress bar, shows log output directly |

### `show_output_default=True` behaviour

- Progress bar area is hidden
- Log output is visible immediately (no "Show output" toggle)
- Use this for tool/maintenance commands (repair, cache clean) where there is no meaningful progress percentage

## Running installs (the standard install flow)

1. Build a command with `flatpak_api.get_install_call(app_id, *flags)` where `flags = ["--user"]` or `["--system"]`
2. `enqueue(app_id, app_name)` — **without** `show_output_default` (defaults to `False`, shows progress bar)
3. `GLib.idle_add(self._navigate_home)` — pop back to home so the Pending tab is accessible
4. Stream stdout into `queue_item.append_output(line)` (must call via `GLib.idle_add` from threads)
5. Call `queue_item.set_status("done")` or `"failed"` when the process exits

## Dialog patterns

- **`Adw.PreferencesDialog`** — settings/tools dialogs (`ParametersDialog`, `ToolsDialog`). Use `self.force_close()` to dismiss programmatically.
- **`Adw.AlertDialog`** — confirmation dialogs (`InstallDialog`, uninstall). Auto-closes after a response.
- **`Adw.NavigationView`** — main navigation stack (`app_window.navigation_view`). Push pages with `navigation_view.push(page)`, pop with `pop_to_page`.

## win.* actions (hamburger menu)

Registered in `app_window._create_home_content()`. To add a new menu entry:
1. `menu.append(_("Label"), "win.action_name")`
2. Add `("action_name", self._on_menu_action_name)` to the loop that creates `Gio.SimpleAction`
3. Implement `_on_menu_action_name(self, _action, _param)`

## FlatpakApi sandbox escape

```python
def _cmd(self, *args) -> list:
    prefix = (
        ["flatpak-spawn", "--host", "--directory=/"]
        if self.is_running_flatpak()   # checks FLATPAK_ID env var
        else []
    )
    return prefix + ["flatpak"] + list(args)
```

Every `get_*_call()` method returns a plain list — pass directly to `subprocess.Popen` or `subprocess.run`.
