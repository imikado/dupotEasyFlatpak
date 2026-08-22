import json
import os
import re
import shutil
import urllib.error
import urllib.request

_USER_AGENT = "dupotEasyFlatpak"


class GithubApi:

    _URL_RE = re.compile(r"github\.com[:/]+([^/\s]+)/([^/\s]+?)(?:\.git)?/?$")

    def parse_owner_repo(self, url: str) -> tuple | None:
        match = self._URL_RE.search((url or "").strip())
        if not match:
            return None
        return match.group(1), match.group(2)

    def _get_json(self, url: str) -> object | None:
        req = urllib.request.Request(
            url,
            headers={
                "Accept": "application/vnd.github+json",
                "User-Agent": _USER_AGENT,
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as response:
                return json.loads(response.read().decode())
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError):
            return None

    @staticmethod
    def _extract_flatpak_asset(release_obj: dict) -> dict | None:
        for asset in release_obj.get("assets", []):
            name = asset.get("name", "")
            if name.endswith(".flatpak"):
                body = (release_obj.get("body") or "").strip()
                # A short, useful subtitle — repeating the asset filename on
                # every row is pointless. Use the first non-empty line of
                # the release notes; the expander reveals the rest.
                summary = ""
                for line in body.splitlines():
                    line = line.strip().lstrip("#").strip()
                    if line:
                        summary = line
                        break
                if len(summary) > 100:
                    summary = summary[:99].rstrip() + "…"

                return {
                    "tag_name": release_obj.get("tag_name", ""),
                    "asset_name": name,
                    "download_url": asset.get("browser_download_url", ""),
                    "body": body,
                    "summary": summary,
                }
        return None

    def get_latest_release_flatpak_asset(self, owner: str, repo: str) -> dict | None:
        data = self._get_json(
            f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
        )
        if data is None:
            return None
        return self._extract_flatpak_asset(data)

    def get_releases_with_flatpak_asset(
        self, owner: str, repo: str, limit: int = 10, page: int = 1
    ) -> list[dict]:
        """One page of releases (newest first) that publish a .flatpak
        asset — `limit` per page, `page` starting at 1."""
        data = self._get_json(
            f"https://api.github.com/repos/{owner}/{repo}/releases"
            f"?per_page={limit}&page={page}"
        )
        if not data:
            return []

        releases = []
        for release_obj in data:
            asset = self._extract_flatpak_asset(release_obj)
            if asset:
                releases.append(asset)
        return releases

    def download_asset(self, download_url: str, dest_path: str) -> bool:
        if not download_url:
            return False

        req = urllib.request.Request(
            download_url,
            headers={
                "Accept": "application/octet-stream",
                "User-Agent": _USER_AGENT,
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                with open(dest_path, "wb") as f:
                    shutil.copyfileobj(response, f)
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError):
            return False

        # A "successful" request that came back empty (redirect not followed
        # correctly, rate-limited HTML error page, ...) is still a failure —
        # don't let an empty/corrupt bundle reach the install step.
        return os.path.getsize(dest_path) > 0
