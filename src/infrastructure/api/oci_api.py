import base64
import json
import re
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

from domain.contract.oci_api_contract import OciApiContract

_MANIFEST_ACCEPT = (
    "application/vnd.oci.image.index.v1+json,"
    "application/vnd.oci.image.manifest.v1+json,"
    "application/vnd.docker.distribution.manifest.list.v2+json,"
    "application/vnd.docker.distribution.manifest.v2+json"
)

_PREFERRED_OCI_ARCH = "amd64"


class OciApi(OciApiContract):
    """Best-effort enrichment for apps served from an OCI-based flatpak
    repository (e.g. Fedora's registry.fedoraproject.org) — flatpak's OCI
    export embeds the app's appstream XML, icon and sizes as labels on the
    image config blob, in place of Flathub's REST API.
    """

    _TIMEOUT = 10

    def get_enrichment_by_app_id(self, registry_url: str, app_id: str) -> object | None:
        # There's no reliable way to go from a flatpak app id back to its
        # OCI repository path other than guessing: OCI repo names must be
        # lowercase, and this convention (last dotted segment, lowercased —
        # e.g. "com.abisource.AbiWord" -> "abiword") holds for most apps on
        # Fedora's registry but not all. A miss just means no enrichment
        # for this app, not an error — the caller keeps its bare fallback.
        repo_name = app_id.rsplit(".", 1)[-1].lower()
        base_url = registry_url[len("oci+"):] if registry_url.startswith("oci+") else registry_url
        base_url = base_url.rstrip("/")

        labels = self._get_config_labels(base_url, repo_name)
        if labels is None:
            return None

        appdata_xml = labels.get("org.freedesktop.appstream.appdata")
        raw_obj = self._parse_appstream_xml(appdata_xml, app_id) if appdata_xml else self._empty_raw_obj(app_id)

        if not raw_obj.get("name") and labels.get("name"):
            raw_obj["name"] = labels["name"]

        for label_key, obj_key in (
            ("org.flatpak.download-size", "download_size"),
            ("org.flatpak.installed-size", "installed_size"),
        ):
            try:
                raw_obj[obj_key] = int(labels.get(label_key, 0))
            except (TypeError, ValueError):
                pass

        ref_parts = (labels.get("org.flatpak.ref") or "").split("/")
        if len(ref_parts) >= 3 and ref_parts[2]:
            raw_obj["arches"] = [ref_parts[2]]

        icon_bytes = self._decode_data_uri(
            labels.get("org.freedesktop.appstream.icon-128")
            or labels.get("org.freedesktop.appstream.icon-64")
        )

        return {"raw_obj": raw_obj, "icon_bytes": icon_bytes}

    def _get_config_labels(self, base_url: str, repo_name: str) -> dict | None:
        manifest = self._fetch_json(f"{base_url}/v2/{repo_name}/manifests/latest", _MANIFEST_ACCEPT)
        if manifest is None:
            return None

        if "manifests" in manifest:
            # Multi-arch index — resolve to a single platform's manifest.
            sub_manifest = self._pick_platform_manifest(manifest.get("manifests", []))
            if sub_manifest is None or "digest" not in sub_manifest:
                return None
            manifest = self._fetch_json(
                f"{base_url}/v2/{repo_name}/manifests/{sub_manifest['digest']}", _MANIFEST_ACCEPT
            )
            if manifest is None:
                return None

        config = manifest.get("config") or {}
        if "digest" not in config:
            return None

        config_obj = self._fetch_json(
            f"{base_url}/v2/{repo_name}/blobs/{config['digest']}", "application/json"
        )
        if config_obj is None:
            return None

        return config_obj.get("config", {}).get("Labels") or {}

    @staticmethod
    def _pick_platform_manifest(manifest_list: list) -> dict | None:
        for entry in manifest_list:
            if entry.get("platform", {}).get("architecture") == _PREFERRED_OCI_ARCH:
                return entry
        return manifest_list[0] if manifest_list else None

    def _fetch_json(self, url: str, accept: str) -> dict | None:
        req = urllib.request.Request(url, headers={"Accept": accept})
        try:
            with urllib.request.urlopen(req, timeout=self._TIMEOUT) as response:
                return json.loads(response.read().decode())
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ValueError, ConnectionError):
            return None

    @staticmethod
    def _decode_data_uri(data_uri: str | None) -> bytes | None:
        if not data_uri:
            return None
        match = re.match(r"data:[^;]+;base64,(.*)", data_uri, re.DOTALL)
        if not match:
            return None
        b64 = match.group(1)
        padding = len(b64) % 4
        if padding:
            b64 += "=" * (4 - padding)
        try:
            return base64.b64decode(b64)
        except (ValueError, TypeError):
            return None

    @staticmethod
    def _empty_raw_obj(app_id: str) -> dict:
        # Every one of these keys is read via direct indexing (not .get())
        # by AppstreamRepository.insert_from_raw_object, so they must
        # always be present even when the appstream XML is missing/unparsable.
        return {
            "app_id": app_id,
            "name": "",
            "summary": "",
            "description": "",
            "project_license": "",
            "developer_name": "",
            "icon": "",
            "main_categories": "",
            "verification_verified": False,
        }

    def _parse_appstream_xml(self, xml_text: str, app_id: str) -> dict:
        raw_obj = self._empty_raw_obj(app_id)
        try:
            root = ET.fromstring(xml_text)
        except ET.ParseError:
            return raw_obj

        component = root if root.tag == "component" else root.find("component")
        if component is None:
            return raw_obj

        def text_of(tag: str) -> str:
            el = component.find(tag)
            return el.text.strip() if el is not None and el.text else ""

        raw_obj["name"] = text_of("name")
        raw_obj["summary"] = text_of("summary")
        raw_obj["developer_name"] = text_of("developer_name")
        raw_obj["project_license"] = text_of("project_license")

        description_el = component.find("description")
        if description_el is not None:
            inner = "".join(ET.tostring(child, encoding="unicode") for child in description_el)
            raw_obj["description"] = inner or (description_el.text or "").strip()

        categories = [
            cat.text.strip() for cat in component.findall("categories/category") if cat.text
        ]
        if categories:
            raw_obj["main_categories"] = categories[0]
            raw_obj["categories"] = categories

        urls = {}
        for url_el in component.findall("url"):
            url_type = url_el.get("type")
            if url_type in ("homepage", "bugtracker", "donation") and url_el.text:
                urls[url_type] = url_el.text.strip()
        if urls:
            raw_obj["urls"] = urls

        screenshots = []
        for shot in component.findall("screenshots/screenshot"):
            image_el = shot.find("image")
            if image_el is not None and image_el.text:
                src = image_el.text.strip()
                # This feed only ever has one image per screenshot (no
                # separate preview/full-size variants) — reuse it for both
                # so update_from_raw_object_with_id still keeps it.
                screenshots.append(
                    {"sizes": [{"width": "500", "src": src}, {"width": "800", "src": src}]}
                )
        if screenshots:
            raw_obj["screenshots"] = screenshots

        releases = []
        for release_el in component.findall("releases/release"):
            version = release_el.get("version")
            timestamp = release_el.get("timestamp")
            if version and timestamp:
                try:
                    releases.append({"version": version, "timestamp": int(timestamp)})
                except ValueError:
                    continue
        if releases:
            raw_obj["releases"] = releases

        return raw_obj
