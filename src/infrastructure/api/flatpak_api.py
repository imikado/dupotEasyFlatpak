import os
import subprocess

from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.entity.flatpak_history_entity import FlatpakHistoryEntity
from domain.entity.flatpakrepo_entity import FlatpakRepoEntity
from domain.entity.installed_version_entity import InstalledVersionEntity
from domain.entity.remote_flatpak_app_entity import RemoteFlatpakAppEntity
from domain.entity.update_available_entity import UpdateAvailableEntity
from infrastructure.repository.pinned_apps_repository import PinnedAppsRepository


class FlatpakApi(FlatpakApiContract):

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._history_cache_by_id_list = {}
        return cls._instance

    def is_running_flatpak(self) -> bool:
        return bool(os.environ.get("FLATPAK_ID"))

    def _cmd(self, *args) -> list:
        prefix = (
            ["flatpak-spawn", "--host", "--directory=/"]
            if self.is_running_flatpak()
            else []
        )
        return prefix + ["flatpak"] + list(args)

    def _cmd_root(self, *args) -> list:
        # Same as _cmd but elevates via pkexec. Flatpak refuses to update a
        # system-wide installation to a specific --commit under a normal
        # (polkit-authenticated) call — it requires real root, unlike plain
        # "update to latest" — so system-scope downgrades need this.
        #
        # `env -u SHELL` strips the SHELL var forwarded from inside the
        # sandbox before pkexec sees it: pkexec requires SHELL (if set) to
        # be a line in /etc/shells, and the sandbox-forwarded value doesn't
        # match the host's /etc/shells, so pkexec refuses to run at all.
        # Unset it and pkexec falls back to the target user's own shell.
        prefix = (
            ["flatpak-spawn", "--host", "--directory=/"]
            if self.is_running_flatpak()
            else []
        )
        return prefix + ["env", "-u", "SHELL", "pkexec", "flatpak"] + list(args)

    def get_installed_app_id_list(self) -> list[str]:
        seen = set()
        for scope in ("--user", "--system"):
            result = subprocess.run(
                self._cmd("list", "--app", scope, "--columns=application"),
                capture_output=True,
                text=True,
            )
            for line in result.stdout.splitlines():
                app_id = line.strip()
                if app_id:
                    seen.add(app_id)
        return list(seen)

    def get_installed_list(self) -> list[InstalledVersionEntity]:
        result = subprocess.run(
            self._cmd("list", "--columns=application,version"),
            capture_output=True,
            text=True,
        )
        installed_list = []
        for line in result.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) >= 2:
                installed_list.append(
                    InstalledVersionEntity(parts[0].strip(), parts[1].strip())
                )
        return installed_list

    def get_installed_app_list(self) -> list[RemoteFlatpakAppEntity]:
        result = subprocess.run(
            self._cmd("list", "--app", "--columns=application,name,version"),
            capture_output=True,
            text=True,
        )
        installed_list = []
        for line in result.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) < 1:
                continue
            app_id = parts[0].strip()
            if not app_id:
                continue
            name = parts[1].strip() if len(parts) >= 2 else app_id
            version = parts[2].strip() if len(parts) >= 3 else ""
            installed_list.append(RemoteFlatpakAppEntity(app_id, name, version))
        return installed_list

    def get_number_of_updates(self) -> int:
        return len(self.get_available_update_list())

    def get_available_update_list(self) -> list[UpdateAvailableEntity]:

        # Best-effort: some third-party remotes (e.g. single-app sideload
        # repos) don't publish an appstream/appstream2 branch at all, so
        # this always prints "No such ref" for them — harmless, and not
        # something the user needs to see at every startup.
        subprocess.run(self._cmd("update", "--appstream"), capture_output=True)

        installed: dict[tuple[str, str], str] = {}
        for scope in ("--user", "--system"):
            result = subprocess.run(
                self._cmd("list", scope, "--columns=application,version,branch"),
                capture_output=True,
                text=True,
            )
            for line in result.stdout.splitlines():
                parts = line.split("\t")
                if len(parts) >= 3:
                    installed[(parts[0].strip(), parts[2].strip())] = parts[1].strip()

        available_update_list = []
        seen_ids: set[str] = set()

        for scope in ("--user", "--system"):
            result = subprocess.run(
                self._cmd(
                    "remote-ls",
                    "--updates",
                    scope,
                    "--columns=application,name,version,branch",
                ),
                capture_output=True,
                text=True,
            )
            for line in result.stdout.splitlines():
                parts = line.split("\t")
                if len(parts) < 1:
                    continue
                app_id = parts[0].strip()
                if not app_id or app_id in seen_ids:
                    continue
                name = parts[1].strip() if len(parts) >= 2 else app_id
                version = parts[2].strip() if len(parts) >= 3 else ""
                branch = parts[3].strip() if len(parts) >= 4 else ""

                installed_version = installed.get((app_id, branch))
                if installed_version is not None and installed_version == version:
                    continue

                seen_ids.add(app_id)
                available_update_list.append(
                    UpdateAvailableEntity(app_id, name, version)
                )

        return available_update_list

    def get_info_by_id(self, app_id: str) -> subprocess.CompletedProcess[bytes]:
        return subprocess.run(self._cmd("info", app_id), capture_output=True)

    def is_app_id_installed(self, app_id: str) -> bool:
        result = self.get_info_by_id(app_id)
        installed = result.returncode == 0

        return installed

    def uninstall_by_id(self, app_id: str, delete_data: bool = False):
        cmd = self._cmd("uninstall", app_id, "-y")
        if delete_data:
            cmd.append("--delete-data")
        subprocess.run(cmd, capture_output=True)

    def get_install_call(self, app_id: str, repo_id: str = "flathub", *flags) -> list:
        return self._cmd("install", repo_id, app_id, "-y", *flags)

    def get_update_call(self, app_id: str) -> list:
        result = subprocess.run(
            self._cmd("list", "--user", "--columns=application"),
            capture_output=True,
            text=True,
        )
        user_ids = {l.strip() for l in result.stdout.splitlines() if l.strip()}
        scope = "--user" if app_id in user_ids else "--system"
        return self._cmd("update", scope, app_id, "-y")

    def get_update_all_user_scope_call(self) -> list:
        return self._cmd("update", "--user", "-y")

    def get_update_all_system_scope_call(self) -> list:
        return self._cmd("update", "--system", "-y")

    def get_override_filesystem_call(self, app_id: str, filesystem: str) -> list:
        return self._cmd("override", "--user", app_id, f"--filesystem={filesystem}")

    def get_override_filesystems(self, app_id: str) -> list[str]:
        result = subprocess.run(
            self._cmd("override", "--user", "--show", app_id),
            capture_output=True,
            text=True,
        )
        for line in result.stdout.splitlines():
            if line.startswith("filesystems="):
                raw = line[len("filesystems=") :].rstrip(";")
                return [v for v in raw.split(";") if v.strip()]
        return []

    def get_installation_scope(self, app_id: str) -> str:
        result = subprocess.run(
            self._cmd("list", "--user", "--columns=application"),
            capture_output=True,
            text=True,
        )
        user_ids = {l.strip() for l in result.stdout.splitlines() if l.strip()}
        return "user" if app_id in user_ids else "system"

    def get_downgrade_call(self, app_id: str, commit: str, *flags) -> list:
        # history is newest-first, so history[0] is the latest available
        # commit — "downgrading" to it just means going back to latest,
        # so drop the pin instead of pinning to it.
        history = self.get_history_list_by_id(app_id)
        if history and history[0].commit == commit:
            PinnedAppsRepository().delete(app_id)
        else:
            PinnedAppsRepository().insert_or_update(app_id, commit)

        args = ["update", f"--commit={commit}", *flags, app_id, "-y"]
        if "--system" in flags:
            return self._cmd_root(*args)
        return self._cmd(*args)

    def update_version_by_id_and_commit(
        self, app_id: str, commit: str
    ) -> subprocess.CompletedProcess:
        return subprocess.run(
            self._cmd("update", "-y", f"--commit={commit}", app_id),
            capture_output=True,
            text=True,
        )

    def run_by_id(self, app_id: str):
        subprocess.Popen(self._cmd("run", app_id))

    def get_installed_commit_by_id(self, app_id: str) -> str | None:
        result = subprocess.run(
            self._cmd("info", "--show-commit", app_id),
            capture_output=True,
            text=True,
        )
        commit = result.stdout.strip()
        return commit if commit else None

    def ensure_flathub_remote(self):

        subprocess.run(
            self._cmd(
                "remote-add",
                "--if-not-exists",
                "--system",
                "flathub",
                "https://dl.flathub.org/repo/flathub.flatpakrepo",
            ),
            capture_output=False,
        )

        subprocess.run(
            self._cmd(
                "remote-add",
                "--if-not-exists",
                "--user",
                "flathub",
                "https://dl.flathub.org/repo/flathub.flatpakrepo",
            ),
            capture_output=False,
        )

    def get_remote_add_call(self, id: str, url: str, scope: str = "--user") -> list:
        return self._cmd("remote-add", "--if-not-exists", scope, id, url)

    def add_remote(self,id:str,url:str,scope:str="--user")-> tuple[bool, str]:
        result = subprocess.run(
            self.get_remote_add_call(id, url,scope),
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            error_message = (result.stderr or result.stdout).strip()
            print(f"[add_remote] ERROR: {error_message}")
            return False, error_message

        return True, ""

    def verify_remote(self, id: str, scope: str = "--user") -> tuple[bool, str]:
        # Querying the repo's summary is the only way to know it's actually
        # reachable and valid — remote-add itself never touches the network
        # for a plain repo URL, it just writes the config.
        try:
            result = subprocess.run(
                self._cmd("remote-ls", scope, id),
                capture_output=True,
                text=True,
                timeout=30,
            )
        except subprocess.TimeoutExpired:
            return False, _("The repository did not respond in time")

        if result.returncode != 0:
            error_message = (result.stderr or result.stdout).strip()
            print(f"[verify_remote] ERROR: {error_message}")
            return False, error_message

        return True, ""

    def remote_exists(self, id: str, scope: str = "--user") -> bool:
        result = subprocess.run(
            self._cmd("remotes", scope, "--columns=name"),
            capture_output=True,
            text=True,
        )
        names = {line.strip() for line in result.stdout.splitlines()}
        return id in names

    def get_remote_delete_call(self, id: str, scope: str = "--user") -> list:
        return self._cmd("remote-delete", scope, "--force", id)

    def remove_remote(self, id: str, scope: str = "--user") -> tuple[bool, str]:
        result = subprocess.run(
            self.get_remote_delete_call(id, scope),
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            error_message = (result.stderr or result.stdout).strip()
            print(f"[remove_remote] ERROR: {error_message}")
            return False, error_message

        return True, ""

    def get_remote_modify_call(self, id: str, url: str, scope: str = "--user") -> list:
        return self._cmd("remote-modify", scope, f"--url={url}", id)

    def modify_remote(self, id: str, url: str, scope: str = "--user") -> tuple[bool, str]:
        result = subprocess.run(
            self.get_remote_modify_call(id, url, scope),
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            error_message = (result.stderr or result.stdout).strip()
            print(f"[modify_remote] ERROR: {error_message}")
            return False, error_message

        return True, ""


    def get_flatpak_bundle_info(self, file_path: str) -> dict:
        info = {}

        # Derive a candidate app_id from filename as fallback
        import os

        basename = os.path.basename(file_path)
        if basename.endswith(".flatpak"):
            info["name"] = basename[: -len(".flatpak")]

        try:
            from gi.repository import GLib

            with open(file_path, "rb") as f:
                data = f.read()
            gbytes = GLib.Bytes.new(data)
            variant = GLib.Variant.new_from_bytes(
                GLib.VariantType.new("(a{sv}aya{sv})"),
                gbytes,
                False,
            )
            metadata_dict = variant.get_child_value(0)
            for i in range(metadata_dict.n_children()):
                entry = metadata_dict.get_child_value(i)
                key = entry.get_child_value(0).get_string()
                value_variant = entry.get_child_value(1).get_variant()
                vtype = value_variant.get_type_string()
                if vtype == "s":
                    info[key] = value_variant.get_string()
                elif vtype == "ay":
                    info[key] = bytes(value_variant.get_data_as_bytes().get_data())
        except Exception:
            pass

        return info

    def get_install_bundle_call(self, file_path: str, *flags) -> list:
        return self._cmd("install", "--bundle", *flags, file_path, "-y")

    def get_history_list_by_id(self, app_id: str) -> list[FlatpakHistoryEntity]:
        if app_id in self._history_cache_by_id_list:
            return self._history_cache_by_id_list[app_id]

        flatpak_history_list = []

        result = subprocess.run(
            self._cmd("remote-info", "--user", "--log", "flathub", app_id),
            capture_output=True,
            text=True,
        )

        commit = subject = date = None
        for line in result.stdout.splitlines():
            line = line.strip()
            if line.startswith("Commit:"):
                commit = line[len("Commit:") :].strip()
            elif line.startswith("Subject:"):
                subject = line[len("Subject:") :].strip()
            elif line.startswith("Date:"):
                date = line[len("Date:") :].strip()
            elif line == "" and commit and subject and date:
                flatpak_history_list.append(FlatpakHistoryEntity(commit, subject, date))
                commit = subject = date = None

        if commit and subject and date:
            flatpak_history_list.append(FlatpakHistoryEntity(commit, subject, date))

        self._history_cache_by_id_list[app_id] = flatpak_history_list
        return flatpak_history_list

    def get_running_flatpak_processes(self) -> list[dict]:
        """Return flatpak install/update processes running outside this app.

        Each entry: {"pid": int, "app_id": str, "action": "install"|"update"}
        """
        if self.is_running_flatpak():
            cmd = ["flatpak-spawn", "--host", "ps", "-eo", "pid,args"]
        else:
            cmd = ["ps", "-eo", "pid,args"]

        result = subprocess.run(cmd, capture_output=True, text=True)
        own_pid = os.getpid()
        found = []

        for line in result.stdout.splitlines()[1:]:
            parts = line.strip().split(None, 1)
            if len(parts) < 2:
                continue
            try:
                pid = int(parts[0])
            except ValueError:
                continue
            if pid == own_pid:
                continue
            args = parts[1].split()
            flatpak_idx = next(
                (
                    i
                    for i, a in enumerate(args)
                    if a == "flatpak" or a.endswith("/flatpak")
                ),
                None,
            )
            if flatpak_idx is None:
                continue
            sub = args[flatpak_idx + 1 :]
            action = next((a for a in sub if a in ("install", "update")), None)
            if not action:
                continue
            action_idx = sub.index(action)
            app_id = next(
                (
                    a
                    for a in sub[action_idx + 1 :]
                    if "." in a
                    and not a.startswith("-")
                    and a not in ("flathub", "flathub-beta")
                ),
                "",
            )
            found.append({"pid": pid, "app_id": app_id, "action": action})

        return found

    def is_pid_running(self, pid: int) -> bool:
        """Return True while the given PID is still alive."""
        if self.is_running_flatpak():
            r = subprocess.run(
                ["flatpak-spawn", "--host", "ps", "-p", str(pid)],
                capture_output=True,
            )
            return r.returncode == 0
        return os.path.exists(f"/proc/{pid}")

    def clean_cache(self):
        subprocess.run(
            self._cmd("run", "--command=fc-cache", "org.dupot.easyflatpak", "-f", "-v"),
            capture_output=False,
        )

    def get_clean_cache_call(self) -> list:
        return self._cmd("run", "--command=fc-cache", "org.dupot.easyflatpak", "-f", "-v")

    def get_repair_user_call(self) -> list:
        return self._cmd("repair", "--user")

    def get_remote_app_list(self,flatpakRepoId:str)->list[RemoteFlatpakAppEntity]:
        result = subprocess.run(
            self._cmd(
                "remote-ls",
                flatpakRepoId,
                "--columns=application,name,version",
            ),
            capture_output=True,
            text=True,
        )

        remote_app_list = []
        for line in result.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            app_id = parts[0].strip()
            if not app_id:
                continue
            name = parts[1].strip()
            remote_app_list.append(RemoteFlatpakAppEntity(app_id, name,""))

        return remote_app_list

    def get_remote_repo_list(self) -> list[FlatpakRepoEntity]:
        result = subprocess.run(
            self._cmd("remotes", "-u","--columns=name,url"),
            capture_output=True,
            text=True,
        )
        remote_repo_list = []
        for line in result.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) < 2 or '/build-repo' in parts[1] or not parts[1].startswith('http'):
                continue
            remote_repo_list.append(
                FlatpakRepoEntity(
                    {"id": parts[0].strip(), "url": parts[1].strip(), "api": "","scope":"--user"}
                )
            )

        resultsystem = subprocess.run(
            self._cmd("remotes", "-u","--columns=name,url"),
            capture_output=True,
            text=True,
        )
        for line in resultsystem.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) < 2 or '/build-repo' in parts[1] or not parts[1].startswith('http'):
                continue
            remote_repo_list.append(
                FlatpakRepoEntity(
                    {"id": parts[0].strip(), "url": parts[1].strip(), "api": "","scope":"--system"}
                )
            )
        
        return remote_repo_list

