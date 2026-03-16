import os
import subprocess

from domain.contract.flatpak_api_contract import FlatpakApiContract


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

    def get_number_of_updates(self) -> int:
        result = subprocess.run(
            self._cmd("flatpak", "remote-ls", "--updates"),
            capture_output=True,
            text=True,
        )
        return len([l for l in result.stdout.splitlines() if l.strip()])

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

    def get_override_filesystem_call(self, app_id: str, filesystem: str) -> list:
        return self._cmd("override", "--user", app_id, f"--filesystem={filesystem}")
