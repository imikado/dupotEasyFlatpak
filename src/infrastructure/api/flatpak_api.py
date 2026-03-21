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
        result = subprocess.run(
            self._cmd("list", "--app", "--columns=application"),
            capture_output=True,
            text=True,
        )
        return [line.strip() for line in result.stdout.splitlines() if line.strip()]

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
        result = subprocess.run(
            self._cmd("remote-ls", "--updates", "--columns=application,name,version"),
            capture_output=True,
            text=True,
        )
        available_update_list = []
        for line in result.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) >= 3:
                available_update_list.append(
                    UpdateAvailableEntity(
                        parts[0].strip(), parts[1].strip(), parts[2].strip()
                    )
                )
            elif len(parts) >= 2:
                available_update_list.append(
                    UpdateAvailableEntity(parts[0].strip(), parts[1].strip(), "")
                )
        return available_update_list

    def get_info_by_id(self, app_id: str) -> subprocess.CompletedProcess[bytes]:
        return subprocess.run(self._cmd("info", app_id), capture_output=True)

    def is_app_id_installed(self, app_id: str) -> bool:
        result = self.get_info_by_id(app_id)
        installed = result.returncode == 0

        return installed

    def uninstall_by_id(self, app_id: str):
        subprocess.run(self._cmd("uninstall", app_id, "-y"), capture_output=True)

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
