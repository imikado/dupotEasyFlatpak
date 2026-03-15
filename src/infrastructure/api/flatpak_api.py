import os
import subprocess

from domain.contract.flatpak_api_contract import FlatpakApiContract


class FlatpakApi(FlatpakApiContract):

    def _cmd(self, *args) -> list:
        prefix = ["flatpak-spawn", "--host", "--directory=/"] if os.environ.get("FLATPAK_ID") else []
        return prefix + ["flatpak"] + list(args)

    def get_installed_app_id_list(self) -> list[str]:
        result = subprocess.run(
            self._cmd("list", "--app", "--columns=application"),
            capture_output=True,
            text=True,
        )
        return [line.strip() for line in result.stdout.splitlines() if line.strip()]
