#!/bin/bash
set -e

APP_NAME="MacStats"
APP_PATH="/Applications/${APP_NAME}.app"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.openhoangnc.macstats.plist"

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
