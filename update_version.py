#!/usr/bin/env python3
"""Sync src/assets/json/installed_version.json with the latest <release>
version found in export/flatpak/org.dupot.easyflatpak.appdata.xml.

Usage: ./update_version.py
"""

import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent
APPDATA_PATH = ROOT / "export/flatpak/org.dupot.easyflatpak.appdata.xml"
VERSION_JSON_PATH = ROOT / "src/assets/json/installed_version.json"


def get_latest_version(appdata_path: Path) -> str:
    tree = ET.parse(appdata_path)
    releases = tree.getroot().findall(".//releases/release")
    if not releases:
        raise ValueError(f"no <release> found in {appdata_path}")
    latest = max(releases, key=lambda r: r.get("date", ""))
    version = latest.get("version")
    if not version:
        raise ValueError("latest <release> has no version attribute")
    return version


def main():
    version = get_latest_version(APPDATA_PATH)
    VERSION_JSON_PATH.write_text(json.dumps({"version": version}, indent=4))
    print(f"installed_version.json -> {version}")


if __name__ == "__main__":
    main()
