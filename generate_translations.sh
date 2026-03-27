#!/usr/bin/env bash
# Generate translation files for Easy_flatpak
# Usage: ./generate_translations.sh
#
# Steps:
#   1. Extract all _("...") strings from Python sources → Easy_flatpak.pot
#   2. Merge the pot into each existing .po file
#   3. Compile every .po → .mo

set -euo pipefail

DOMAIN="Easy_flatpak"
SRC_DIR="src"
LOCALES_DIR="src/infrastructure/locales"
POT_FILE="$LOCALES_DIR/$DOMAIN.pot"

LANGUAGES=(ar en es fr it pt_BR ro)

echo "=== Extracting strings from Python sources ==="
find "$SRC_DIR" -name "*.py" | sort | xgettext \
    --language=Python \
    --keyword=_ \
    --from-code=UTF-8 \
    --output="$POT_FILE" \
    --package-name="$DOMAIN" \
    --files-from=-

echo "  → $POT_FILE"

for LANG in "${LANGUAGES[@]}"; do
    PO_FILE="$LOCALES_DIR/$LANG/LC_MESSAGES/$DOMAIN.po"
    MO_FILE="$LOCALES_DIR/$LANG/LC_MESSAGES/$DOMAIN.mo"

    echo ""
    echo "=== [$LANG] ==="

    if [ -f "$PO_FILE" ]; then
        echo "  Merging new strings into existing .po"
        msgmerge --update --no-fuzzy-matching --backup=none "$PO_FILE" "$POT_FILE"
    else
        echo "  Creating new .po from template"
        mkdir -p "$(dirname "$PO_FILE")"
        msginit \
            --input="$POT_FILE" \
            --locale="$LANG" \
            --output="$PO_FILE" \
            --no-translator
    fi

    echo "  Compiling → $MO_FILE"
    msgfmt --output-file="$MO_FILE" "$PO_FILE"
done

echo ""
echo "Done."
