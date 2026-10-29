#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/TouchAir.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

echo "==> Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

SOURCES=(
    "$PROJECT_DIR/Sources/AirDropIcon.swift"
    "$PROJECT_DIR/Sources/AirDropHelper.swift"
    "$PROJECT_DIR/Sources/FinderActionHelper.swift"
    "$PROJECT_DIR/Sources/FinderMonitor.swift"
    "$PROJECT_DIR/Sources/TouchBarManager.swift"
    "$PROJECT_DIR/Sources/AppDelegate.swift"
    "$PROJECT_DIR/Sources/main.swift"
)

echo "==> Compiling for Apple Silicon (arm64)..."
swiftc -O \
    -target arm64-apple-macos11.0 \
    "${SOURCES[@]}" \
    -o "$MACOS_DIR/TouchAir_arm64"

echo "==> Compiling for Intel (x86_64)..."
swiftc -O \
    -target x86_64-apple-macos11.0 \
    "${SOURCES[@]}" \
    -o "$MACOS_DIR/TouchAir_x86_64"

echo "==> Creating Universal 2 Binary (arm64 + x86_64)..."
lipo -create -output "$MACOS_DIR/TouchAir" "$MACOS_DIR/TouchAir_arm64" "$MACOS_DIR/TouchAir_x86_64"
rm -f "$MACOS_DIR/TouchAir_arm64" "$MACOS_DIR/TouchAir_x86_64"

echo "==> Copying Info.plist and AppIcon.icns..."
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "==> Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Build completed successfully: $APP_BUNDLE"
lipo -info "$MACOS_DIR/TouchAir"
