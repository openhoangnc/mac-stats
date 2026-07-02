#!/bin/bash
set -e

APP_NAME="MacStats"
APP_BUNDLE="${APP_NAME}.app"

echo "=== Building ${APP_NAME} (Optimized) ==="

# 1. Generate icon
echo "[1/4] Generating AppIcon.icns..."
python3 generate_icon.py || echo "Warning: Icon generation failed, continuing..."

# 2. Compile Swift executable with maximum size & performance optimizations
echo "[2/4] Compiling Swift source code..."
swiftc -Osize -wmo \
    -module-name MacStats \
    -Xlinker -dead_strip \
    -framework AppKit \
    -framework IOKit \
    -framework Foundation \
    StatsEngine.swift \
    StatusBarView.swift \
    AppDelegate.swift \
    main.swift \
    -o "${APP_NAME}_bin"

# Strip debug symbols and local symbols to minimize binary
strip -x "${APP_NAME}_bin" || true

# 3. Create .app bundle structure
echo "[3/4] Packaging ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

mv "${APP_NAME}_bin" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp Info.plist "${APP_BUNDLE}/Contents/"

if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${APP_BUNDLE}/Contents/Resources/"
fi

# 4. Sign binary locally
echo "[4/4] Signing app bundle locally..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "=== Build Complete! ==="
echo "App created at: $(pwd)/${APP_BUNDLE}"
echo "Run with: open ${APP_BUNDLE}"
