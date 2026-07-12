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
    
    # 1. Unregister login item via App binary before termination/deletion
    if [ -x "${APP_PATH}/Contents/MacOS/${APP_NAME}" ]; then
        echo "--> Unregistering Open at Login item..."
        "${APP_PATH}/Contents/MacOS/${APP_NAME}" --cleanup-login-item 2>/dev/null || true
    fi

    # 2. Terminate running instance
    if pgrep -x "${APP_NAME}" > /dev/null; then
        echo "--> Stopping running ${APP_NAME} process..."
        pkill -x "${APP_NAME}" || killall "${APP_NAME}" 2>/dev/null || true
        sleep 1
    fi

    # 3. Remove LaunchAgent plist and unload from launchctl
    if [ -f "${PLIST_PATH}" ]; then
        echo "--> Removing LaunchAgent auto-start..."
        launchctl bootout "gui/$(id -u)" "${PLIST_PATH}" 2>/dev/null || launchctl unload "${PLIST_PATH}" 2>/dev/null || true
        rm -f "${PLIST_PATH}"
    fi

    # 4. Remove App bundle
    if [ -d "${APP_PATH}" ]; then
        echo "--> Removing ${APP_PATH}..."
        rm -rf "${APP_PATH}"
    fi

    # 5. Remove Preferences
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

# Resolve the directory this script lives in. It is empty when the script is
# piped from `curl ... | bash` (no file on disk), which is how we distinguish a
# local checkout from a remote one-liner install.
SOURCE_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

APP_SRC=""   # path to the .app bundle we will install

if [ -n "${SOURCE_DIR}" ] && [ -f "${SOURCE_DIR}/build.sh" ]; then
    # Local checkout: build from source so local changes are the ones installed.
    echo "[1/3] Local source detected — building ${APP_NAME} from source..."
    ( cd "${SOURCE_DIR}" && ./build.sh )
    APP_SRC="${SOURCE_DIR}/${APP_NAME}.app"
    if [ ! -d "${APP_SRC}" ]; then
        echo "Error: build failed — ${APP_NAME}.app was not produced."
        exit 1
    fi
else
    # Remote install: download the latest prebuilt release.
    echo "[1/3] Downloading latest release of ${APP_NAME}..."
    LATEST_ZIP_URL="https://github.com/${REPO}/releases/latest/download/MacStats.zip"
    if curl -fsSL -o "${TMP_DIR}/MacStats.zip" "${LATEST_ZIP_URL}"; then
        echo "--> Downloaded MacStats.zip from GitHub Release."
        unzip -q "${TMP_DIR}/MacStats.zip" -d "${TMP_DIR}"
        APP_SRC="${TMP_DIR}/${APP_NAME}.app"
    fi
    if [ ! -d "${APP_SRC}" ]; then
        echo "Error: Could not download ${APP_NAME}. Ensure a GitHub release exists, or run this script from a local checkout to build from source."
        exit 1
    fi
fi

echo "[2/3] Installing to ${APP_PATH}..."
# Stop existing app before replacing
if pgrep -x "${APP_NAME}" > /dev/null; then
    echo "--> Closing existing ${APP_NAME} instance..."
    pkill -x "${APP_NAME}" || killall "${APP_NAME}" 2>/dev/null || true
    sleep 1
fi

rm -rf "${APP_PATH}"
cp -R "${APP_SRC}" "${INSTALL_DIR}/"

# Remove quarantine flag so macOS allows running
xattr -r -d com.apple.quarantine "${APP_PATH}" 2>/dev/null || true

echo "[3/3] Launching ${APP_NAME}..."
open "${APP_PATH}"

echo ""
echo "=== Success! ${APP_NAME} is installed and running in your Menu Bar. ==="
echo "To uninstall at any time, run:"
echo "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/uninstall.sh | bash"
