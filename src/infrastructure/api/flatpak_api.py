import os
import subprocess

from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.entity.flatpak_history_entity import FlatpakHistoryEntity
from domain.entity.installed_version_entity import InstalledVersionEntity
from domain.entity.update_available_entity import UpdateAvailableEntity


class FlatpakApi(FlatpakApiContract):

    def _cmd(self, *args) -> list:
        prefix = (
            ["flatpak-spawn", "--host", "--directory=/"]
            if os.environ.get("FLATPAK_ID")
            else []
        )
        return prefix + ["flatpak"] + list(args)

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

    def get_number_of_updates(self) -> int:
        return len(self.get_available_update_list())

    def get_available_update_list(self) -> list[UpdateAvailableEntity]:
        # Build installed (app_id, branch) → version map to detect runtimes
        # already at their latest visible version (same version+branch = commit-only
        # update that would loop endlessly if shown).
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

                # Hide runtimes where the visible version hasn't changed — only
                # a commit difference exists, which causes an infinite update loop.
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

    def get_install_call(self, app_id: str, flags) -> list:
        return self._cmd("install", "flathub", app_id, "-y", flags)

    def get_update_call(self, app_id: str) -> list:
        result = subprocess.run(
            self._cmd("list", "--user", "--columns=application"),
            capture_output=True,
            text=True,
        )
        user_ids = {l.strip() for l in result.stdout.splitlines() if l.strip()}
        scope = "--user" if app_id in user_ids else "--system"
        return self._cmd("update", scope, app_id, "-y")

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
        return self._cmd("update", f"--commit={commit}", *flags, app_id, "-y")

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

        return flatpak_history_list

    def clean_cache(self):

        subprocess.run(
            self._cmd("run", "--command=fc-cache", "org.dupot.easyflatpak", "-f", "-v"),
            capture_output=False,
        )
