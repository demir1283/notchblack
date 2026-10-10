#!/bin/bash
# NotchBlack build script
# Kullanim: ./build.sh  (proje klasorunde calistir)
set -e

APP_NAME="NotchBlack"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "==> Temizleniyor"
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "==> Derleniyor (swiftc)"
swiftc \
  -O \
  -whole-module-optimization \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  "$ROOT"/Sources/*.swift

echo "==> Info.plist kopyalaniyor"
cp "$ROOT/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "==> Ad-hoc imzalaniyor"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Bitti: $APP_BUNDLE"
echo "Acmak icin:  open \"$APP_BUNDLE\""
