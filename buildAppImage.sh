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

# Copy Flutter bundle into AppDir
mkdir -p "$APPDIR"
cp -r "$BUILD_DIR"/* "$APPDIR/"

# Custom AppRun
cp appImage/AppRun "$APPDIR/"
chmod +x "$APPDIR/AppRun"

# Copy .desktop
mkdir -p "$APPDIR/usr/share/applications"
cp "appImage/$APP_NAME.desktop" "$APPDIR/usr/share/applications/"

# Copy icon
ICON_TARGET_DIR="$APPDIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$ICON_TARGET_DIR"
cp "assets/logos/512x512.png" "$ICON_TARGET_DIR/$ICON_NAME"

# Copy OpenGL-related libraries manually (no ldconfig)
GL_LIBS=(libEGL.so.1 libGL.so.1 libgbm.so.1 libdrm.so.2)
mkdir -p "$APPDIR/usr/lib"

for libname in "${GL_LIBS[@]}"; do
  libpath=$(find /usr/lib /lib /usr/lib64 /lib64 -name "$libname" 2>/dev/null | head -n1)
  if [[ -n "$libpath" && -f "$libpath" ]]; then
    echo "✅ Copying $libname from $libpath"
    cp "$libpath" "$APPDIR/usr/lib/"
  else
    echo "⚠️  Warning: $libname not found"
  fi
done

# Package AppImage
linuxdeploy-x86_64.AppImage --appdir "$APPDIR" \
  -d "$APPDIR/usr/share/applications/$APP_NAME.desktop" \
  -i "$ICON_TARGET_DIR/$ICON_NAME" \
  --output appimage
