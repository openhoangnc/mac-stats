#!/bin/bash
set -e

REPO="openhoangnc/mac-stats"
APP_NAME="MacStats"
INSTALL_DIR="/Applications"
APP_PATH="${INSTALL_DIR}/${APP_NAME}.app"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.openhoangnc.macstats.plist"

# Check OS
if [ "$(uname -s)" != "Darwin" ]; then
    echo "Error: MacStats is only supported on macOS."
    exit 1
fi

do_uninstall() {
    echo "=== Uninstalling ${APP_NAME} ==="
    
    # 1. Terminate running instance
    if pgrep -x "${APP_NAME}" > /dev/null; then
        echo "--> Stopping running ${APP_NAME} process..."
        pkill -x "${APP_NAME}" || killall "${APP_NAME}" 2>/dev/null || true
        sleep 1
    fi

    # 2. Remove LaunchAgent plist
    if [ -f "${PLIST_PATH}" ]; then
        echo "--> Removing LaunchAgent auto-start..."
        rm -f "${PLIST_PATH}"
    fi

    # 3. Remove App bundle
    if [ -d "${APP_PATH}" ]; then
        echo "--> Removing ${APP_PATH}..."
        rm -rf "${APP_PATH}"
    fi

    # 4. Remove Preferences
    echo "--> Clearing application preferences..."
    rm -f "${HOME}/Library/Preferences/com.openhoangnc.macstats.plist"

    echo "=== Uninstallation Complete! ${APP_NAME} has been completely removed. ==="
    exit 0
}

# Check for uninstall flag
if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
    do_uninstall
fi

echo "=== Installing ${APP_NAME} ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

LATEST_ZIP_URL="https://github.com/${REPO}/releases/latest/download/MacStats.zip"
DOWNLOADED=0

echo "[1/3] Downloading latest release of ${APP_NAME}..."
if curl -fsSL -o "${TMP_DIR}/MacStats.zip" "${LATEST_ZIP_URL}" 2>/dev/null; then
    echo "--> Downloaded MacStats.zip from GitHub Release."
    DOWNLOADED=1
else
    echo "--> Release zip not available via GitHub Release download yet."
    if [ -f "./build.sh" ]; then
        echo "--> Compiling ${APP_NAME} locally from source..."
        ./build.sh
        if [ -d "${APP_NAME}.app" ]; then
            zip -r -q "${TMP_DIR}/MacStats.zip" "${APP_NAME}.app"
            DOWNLOADED=1
        fi
    fi
fi

if [ $DOWNLOADED -eq 0 ]; then
    echo "Error: Could not obtain ${APP_NAME}.app binary. Please ensure GitHub releases exist or build.sh is present."
    exit 1
fi

echo "[2/3] Installing to ${APP_PATH}..."
# Stop existing app before replacing
if pgrep -x "${APP_NAME}" > /dev/null; then
    echo "--> Closing existing ${APP_NAME} instance..."
    pkill -x "${APP_NAME}" || killall "${APP_NAME}" 2>/dev/null || true
    sleep 1
fi

rm -rf "${APP_PATH}"
if [ -f "${TMP_DIR}/MacStats.zip" ]; then
    unzip -q "${TMP_DIR}/MacStats.zip" -d "${INSTALL_DIR}"
elif [ -d "${APP_NAME}.app" ]; then
    cp -R "${APP_NAME}.app" "${INSTALL_DIR}/"
fi

# Remove quarantine flag so macOS allows running
xattr -r -d com.apple.quarantine "${APP_PATH}" 2>/dev/null || true

echo "[3/3] Launching ${APP_NAME}..."
open "${APP_PATH}"

echo ""
echo "=== Success! ${APP_NAME} is installed and running in your Menu Bar. ==="
echo "To uninstall at any time, run:"
echo "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/uninstall.sh | bash"
