#!/usr/bin/env bash

set -euo pipefail

APP_NAME="dupot_easy_flatpak"
BUILD_DIR="build/linux/x64/release/bundle"
APPDIR="/tmp/dupotEasyFlatpak.AppDir"
ICON_NAME="dupot_easy_flatpak.png"

# Clean up previous build
rm -rf "$APPDIR"

# Build Flutter app for Linux
flutter build linux --release

# Copy full Flutter bundle to AppDir root (to preserve libapp.so, data, icudtl.dat, etc.)
mkdir -p "$APPDIR"
cp -r "$BUILD_DIR"/* "$APPDIR/"

cp appImage/AppRun "$APPDIR/"
chmod +x "$APPDIR/AppRun"


# Ensure icon is placed correctly
ICON_TARGET_DIR="$APPDIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$ICON_TARGET_DIR"
cp "assets/logos/512x512.png" "$ICON_TARGET_DIR/$ICON_NAME"

# Ensure desktop file is present
mkdir -p "$APPDIR/usr/share/applications"
cp "appImage/$APP_NAME.desktop" "$APPDIR/usr/share/applications/"

# Run linuxdeploy to finish packaging into AppImage
./linuxdeploy-x86_64.AppImage --appdir "$APPDIR" \
  -d "$APPDIR/usr/share/applications/$APP_NAME.desktop" \
  -i "$ICON_TARGET_DIR/$ICON_NAME" \
  --output appimage
