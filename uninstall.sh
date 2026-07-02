#!/bin/bash
set -e

APP_NAME="MacStats"
APP_PATH="/Applications/${APP_NAME}.app"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.openhoangnc.macstats.plist"

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
