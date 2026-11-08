#!/usr/bin/env python3
"""Point the <screenshot> URLs of the appdata file at a given git commit,
and add new screenshots (export/screenshots/*.png) to the appdata file and README.md.

Flathub needs immutable screenshot URLs, so they reference a commit hash:
  https://raw.githubusercontent.com/imikado/dupotEasyFlatpak/<commit>/export/screenshots/X.png

Usage:
  ./update_screenshot_urls.py                  # use HEAD (must be pushed)
  ./update_screenshot_urls.py <commit>         # use a specific commit
Options:
  --add-missing     add PNGs not referenced yet to the appdata file and README.md
  --remove-missing  remove entries whose PNG doesn't exist in export/screenshots
  --dry-run         show the result without writing
  --force           skip the "commit is pushed / screenshots committed" checks
"""

import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
APPDATA = os.path.join(ROOT, "export", "flatpak", "org.dupot.easyflatpak.appdata.xml")
README = os.path.join(ROOT, "README.md")
SCREENSHOTS_DIR = "export/screenshots"
URL_PREFIX = "https://raw.githubusercontent.com/imikado/dupotEasyFlatpak/"

URL_RE = re.compile(
    re.escape(URL_PREFIX) + r"(?P<ref>[^/]+)/" + re.escape(SCREENSHOTS_DIR) + r"/(?P<file>[^<\s]+)"
)
BLOCK_RE = re.compile(r"[ \t]*<screenshot\b[^>]*>.*?</screenshot>\n?", re.S)


def git(*args) -> str:
    return subprocess.run(
        ["git", *args], cwd=ROOT, check=True, capture_output=True, text=True
    ).stdout.strip()


def check_commit(commit: str):
    errors = []
    if git("status", "--porcelain", "--", SCREENSHOTS_DIR):
        errors.append(f"uncommitted changes in {SCREENSHOTS_DIR}")
    if not git("branch", "-r", "--contains", commit):
        errors.append(f"commit {commit[:12]} is not on any remote branch (push it first)")
    for f in sorted(os.listdir(os.path.join(ROOT, SCREENSHOTS_DIR))):
        try:
            git("cat-file", "-e", f"{commit}:{SCREENSHOTS_DIR}/{f}")
        except subprocess.CalledProcessError:
            errors.append(f"{f} is not in commit {commit[:12]}")
    if errors:
        sys.exit("error:\n  " + "\n  ".join(errors) + "\n(use --force to ignore)")


# Captions for new screenshots (appdata caption, README label). Fallback: derived from file name.
CAPTIONS = {
    "Screenshot_features.png": ("Features overview", "Features overview"),
    "Screenshot_category_grid.png": ("Category page displayed as grid", "Category apps"),
}


def caption_from_name(name: str, readme: bool = False) -> str:
    if name in CAPTIONS:
        return CAPTIONS[name][1 if readme else 0]
    base = os.path.splitext(name)[0]
    base = re.sub(r"^Screenshot_", "", base)
    text = base.replace("_", " ").strip()
    return text[:1].upper() + text[1:]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("commit", nargs="?", default="HEAD")
    parser.add_argument("--add-missing", action="store_true")
    parser.add_argument("--remove-missing", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    commit = git("rev-parse", "--verify", args.commit + "^{commit}")
    if not args.force:
        check_commit(commit)

    with open(APPDATA, encoding="utf-8") as fh:
        content = fh.read()

    on_disk = set(os.listdir(os.path.join(ROOT, SCREENSHOTS_DIR)))
    referenced = [m.group("file") for m in URL_RE.finditer(content)]
    missing = [f for f in referenced if f not in on_disk]
    unreferenced = sorted(f for f in on_disk if f.endswith(".png") and f not in referenced)

    old_refs = {m.group("ref") for m in URL_RE.finditer(content)}
    content = URL_RE.sub(lambda m: f"{URL_PREFIX}{commit}/{SCREENSHOTS_DIR}/{m.group('file')}", content)

    if args.remove_missing and missing:
        def drop(block):
            m = URL_RE.search(block.group(0))
            return "" if m and m.group("file") in missing else block.group(0)
        content = BLOCK_RE.sub(drop, content)

    if args.add_missing and unreferenced:
        new_blocks = "".join(
            f"    <screenshot>\n"
            f"      <image>{URL_PREFIX}{commit}/{SCREENSHOTS_DIR}/{f}</image>\n"
            f"      <caption>{caption_from_name(f)}</caption>\n"
            f"    </screenshot>\n"
            for f in unreferenced
        )
        content = re.sub(r"([ \t]*</screenshots>)", lambda m: new_blocks + m.group(1), content, count=1)

    print(f"commit: {commit}  (was: {', '.join(sorted(old_refs)) or '-'})")
    print(f"{len(referenced)} screenshot URL(s) updated")
    if missing:
        print(("removed" if args.remove_missing else "WARNING missing on disk") + ": " + ", ".join(missing))
    if unreferenced:
        print(("added" if args.add_missing else "not referenced (use --add-missing)") + ": " + ", ".join(unreferenced))

    readme_content, readme_added = sync_readme(on_disk) if args.add_missing else (None, [])
    if readme_added:
        print("README.md added: " + ", ".join(readme_added))

    if args.dry_run:
        print("--dry-run: nothing written")
        return
    with open(APPDATA, "w", encoding="utf-8") as fh:
        fh.write(content)
    print(f"written {os.path.relpath(APPDATA, ROOT)}")
    if readme_added:
        with open(README, "w", encoding="utf-8") as fh:
            fh.write(readme_content)
        print("written README.md")


def sync_readme(on_disk: set):
    """Append unreferenced PNGs to the README screenshots table (2 per row)."""
    with open(README, encoding="utf-8") as fh:
        content = fh.read()
    start = content.find("## 📸 Screenshots")
    end = content.find("</table>", start)
    if start < 0 or end < 0:
        print("WARNING README.md: screenshots table not found")
        return content, []
    table = content[start:end]
    new = sorted(f for f in on_disk if f.endswith(".png") and f"{SCREENSHOTS_DIR}/{f}" not in table)
    if not new:
        return content, []

    def cell(f):
        label = caption_from_name(f, readme=True)
        return (
            '<td align="center" width="50%">\n'
            f'<img src="{SCREENSHOTS_DIR}/{f}" alt="{label}"><br><sub>{label}</sub>\n'
            "</td>\n"
        )

    rows = "".join(
        "<tr>\n" + "".join(cell(f) for f in new[i:i + 2]) + "</tr>\n"
        for i in range(0, len(new), 2)
    )
    return content[:end] + rows + content[end:], new


if __name__ == "__main__":
    main()
