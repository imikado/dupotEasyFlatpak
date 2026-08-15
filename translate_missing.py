#!/usr/bin/env python3
"""
Translate empty msgstr entries in all .po files using the Claude API.

Workflow:
  1. Run ./generate_translations.sh  (extracts new strings, merges into .po files)
  2. Run python3 translate_missing.py  (fills in missing translations)
  3. Run ./generate_translations.sh again  (recompiles .mo files)

Requirements:
  ANTHROPIC_API_KEY environment variable must be set.
  No extra Python packages needed (uses stdlib urllib only).
"""

import json
import os
import re
import subprocess
import sys
import urllib.request

LOCALES_DIR = "src/infrastructure/locales"
DOMAIN = "Easy_flatpak"
LANGUAGES = {
    "ar": "Arabic",
    "de": "German",
    "es": "Spanish (Spain)",
    "fr": "French",
    "it": "Italian",
    "pt_BR": "Portuguese (Brazil)",
    "ro": "Romanian",
}
MODEL = "claude-sonnet-4-6"


# ---------------------------------------------------------------------------
# .po parsing
# ---------------------------------------------------------------------------

def _unescape(s: str) -> str:
    return s.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")


def _escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def parse_entries(content: str) -> list[dict]:
    """
    Return list of dicts with keys: msgid, msgstr, full_match, msgstr_raw.
    Only non-header entries (msgid != "") are included.
    """
    pattern = re.compile(
        r'(msgid\s+"((?:[^"\\]|\\.)*)")\n'
        r'(msgstr\s+"((?:[^"\\]|\\.)*)")',
    )
    entries = []
    for m in pattern.finditer(content):
        msgid = _unescape(m.group(2))
        msgstr = _unescape(m.group(4))
        if not msgid:  # skip header
            continue
        entries.append({
            "msgid": msgid,
            "msgstr": msgstr,
            "full_match": m.group(0),
            "msgid_raw": m.group(1),
            "msgstr_raw": m.group(3),
        })
    return entries


# ---------------------------------------------------------------------------
# Claude API call
# ---------------------------------------------------------------------------

def translate_batch(api_key: str, msgids: list[str], language: str) -> dict[str, str]:
    """Call Claude API and return {msgid: translation} dict."""
    system = (
        f"You are a professional software UI translator. "
        f"Translate the given English strings to {language}. "
        f"Rules:\n"
        f"- Keep translations short and natural for a desktop application.\n"
        f"- Preserve placeholders like {{name}}, {{count}}, {{version}} exactly.\n"
        f"- Do NOT translate proper nouns: Flatpak, Flathub, Easy Flatpak.\n"
        f"- Ellipsis (…) must be kept as-is.\n"
        f"- Return ONLY a valid JSON object: {{\"English string\": \"translated string\", ...}}"
    )
    payload = {
        "model": MODEL,
        "max_tokens": 4096,
        "system": system,
        "messages": [
            {
                "role": "user",
                "content": json.dumps(msgids, ensure_ascii=False, indent=2),
            }
        ],
    }
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=json.dumps(payload).encode(),
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        body = json.loads(resp.read())
    text = body["content"][0]["text"]
    # Strip markdown code fences if present
    json_match = re.search(r'\{.*\}', text, re.DOTALL)
    return json.loads(json_match.group() if json_match else text)


# ---------------------------------------------------------------------------
# Per-language processing
# ---------------------------------------------------------------------------

def process_language(lang_code: str, lang_name: str, api_key: str):
    po_path = f"{LOCALES_DIR}/{lang_code}/LC_MESSAGES/{DOMAIN}.po"
    if not os.path.exists(po_path):
        print(f"  [SKIP] {po_path} not found")
        return

    with open(po_path, encoding="utf-8") as f:
        content = f.read()

    entries = parse_entries(content)
    missing = [e for e in entries if not e["msgstr"]]

    if not missing:
        print(f"  Nothing to translate.")
        return

    print(f"  {len(missing)} string(s) to translate…")
    msgids = [e["msgid"] for e in missing]

    translations = translate_batch(api_key, msgids, lang_name)

    applied = 0
    for entry in missing:
        msgid = entry["msgid"]
        if msgid not in translations:
            print(f"  [WARN] no translation returned for: {msgid!r}")
            continue
        translated = translations[msgid]
        new_msgstr = f'msgstr "{_escape(translated)}"'
        # Replace exactly: keep msgid line, replace msgstr line
        old_block = entry["full_match"]
        new_block = entry["msgid_raw"] + "\n" + new_msgstr
        content = content.replace(old_block, new_block, 1)
        applied += 1

    with open(po_path, "w", encoding="utf-8") as f:
        f.write(content)

    # Recompile .mo
    mo_path = f"{LOCALES_DIR}/{lang_code}/LC_MESSAGES/{DOMAIN}.mo"
    subprocess.run(["msgfmt", "--output-file", mo_path, po_path], check=True)
    print(f"  ✓ {applied} translation(s) applied and compiled.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ERROR: ANTHROPIC_API_KEY is not set.", file=sys.stderr)
        sys.exit(1)

    for lang_code, lang_name in LANGUAGES.items():
        print(f"\n[{lang_code}] {lang_name}")
        process_language(lang_code, lang_name, api_key)

    print("\nAll done.")


if __name__ == "__main__":
    main()
