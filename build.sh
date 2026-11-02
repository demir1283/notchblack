#!/bin/bash
# NotchBlack build script
#
# Kullanim:
#   ./build.sh            -> sadece derler (build/NotchBlack.app), test icin
#   ./build.sh --install  -> derler, /Applications'a kurar, build kopyasini siler
set -e

APP_NAME="NotchBlack"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

echo "==> Temizleniyor"
if [ -d "$APP_BUNDLE" ]; then
  "$LSREGISTER" -u "$APP_BUNDLE" 2>/dev/null || true
fi
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
# Spotlight / Launchpad bu klasoru indekslemesin (cift kayit olmasin)
touch "$BUILD_DIR/.metadata_never_index"

echo "==> Derleniyor (swiftc)"
swiftc \
  -O \
  -whole-module-optimization \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  "$ROOT"/Sources/*.swift

echo "==> Info.plist kopyalaniyor"
cp "$ROOT/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "==> Ikon kopyalaniyor"
cp "$ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "==> Ad-hoc imzalaniyor"
codesign --force --deep --sign - "$APP_BUNDLE"

if [ "$1" = "--install" ]; then
  echo "==> /Applications'a kuruluyor"
  pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 0.5
  rm -rf "$INSTALL_PATH"
  cp -R "$APP_BUNDLE" "$INSTALL_PATH"
  "$LSREGISTER" -u "$APP_BUNDLE" 2>/dev/null || true
  rm -rf "$BUILD_DIR"
  # Ikon onbellegini yenile: once paketin tarihini guncelle, sonra yeniden kaydet
  touch "$INSTALL_PATH"
  "$LSREGISTER" -f "$INSTALL_PATH"
  killall iconservicesagent 2>/dev/null || true
  killall Dock 2>/dev/null || true
  open "$INSTALL_PATH"
  echo "==> Kuruldu ve baslatildi: $INSTALL_PATH"
else
  echo "==> Bitti: $APP_BUNDLE"
  echo "Test icin:   open \"$APP_BUNDLE\""
  echo "Kurmak icin: ./build.sh --install"
fi
