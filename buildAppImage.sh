#!/usr/bin/env bash

set -euo pipefail

APP_NAME="dupot_easy_flatpak"
BUILD_DIR="build/linux/x64/release/bundle"
APPDIR="/tmp/dupotEasyFlatpak.AppDir"
ICON_NAME="dupot_easy_flatpak.png"
APP_BINARY="$BUILD_DIR/$APP_NAME"

# Clean up previous build
rm -rf "$APPDIR"

# Build Flutter app for Linux
flutter build linux --release

# Copy full Flutter bundle into AppDir root
mkdir -p "$APPDIR"
cp -r "$BUILD_DIR"/* "$APPDIR/"

# Install custom AppRun (must set LD_LIBRARY_PATH)
cp appImage/AppRun "$APPDIR/"
chmod +x "$APPDIR/AppRun"

# Copy desktop file
mkdir -p "$APPDIR/usr/share/applications"
cp "appImage/$APP_NAME.desktop" "$APPDIR/usr/share/applications/"

# Copy icon
ICON_TARGET_DIR="$APPDIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$ICON_TARGET_DIR"
cp "assets/logos/512x512.png" "$ICON_TARGET_DIR/$ICON_NAME"

# Copy extra graphics libraries to fix black screen (Debian EGL/GL)
GL_LIBS=(libEGL.so.1 libGL.so.1 libgbm.so.1 libdrm.so.2)

mkdir -p "$APPDIR/usr/lib"

for libname in "${GL_LIBS[@]}"; do
  libpath=$(ldconfig -p | grep "$libname" | head -n1 | awk '{print $NF}')
  if [[ -n "$libpath" && -f "$libpath" ]]; then
    echo "✅ Bundling $libname from $libpath"
    cp "$libpath" "$APPDIR/usr/lib/"
  else
    echo "⚠️  Warning: $libname not found via ldconfig"
  fi
done

# Final AppImage packaging with linuxdeploy (don't override AppRun)
linuxdeploy-x86_64.AppImage --appdir "$APPDIR" \
  -d "$APPDIR/usr/share/applications/$APP_NAME.desktop" \
  -i "$ICON_TARGET_DIR/$ICON_NAME" \
  --output appimage
