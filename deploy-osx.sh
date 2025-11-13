#!/usr/bin/env bash
set -e

# Minimal deploy script for macOS using macdeployqt
# Usage: ./deploy-osx.sh [BUILD_DIR] [APP_NAME]
# Example: ./deploy-osx.sh cmake-build-debug tikzit

BUILD_DIR="${1:-cmake-build-debug}"
APP_NAME="${2:-tikzit}"
APP_BUNDLE="${APP_NAME}.app"
EXECUTABLE="${BUILD_DIR}/${APP_NAME}"

echo "Creating ${APP_BUNDLE} from ${EXECUTABLE}"

# Clean old bundle
rm -rf "${APP_BUNDLE}" "${APP_NAME}.dmg"

# Create bundle structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${EXECUTABLE}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Minimal Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key><string>org.yourorg.${APP_NAME}</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleExecutable</key><string>${APP_NAME}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
</dict>
</plist>
EOF

# Copy icon if available
if [[ -f "src/images/tikzit.png" ]]; then
  cp src/images/tikzit.png "${APP_BUNDLE}/Contents/Resources/"
elif [[ -f "src/gui/images/tikzit.png" ]]; then
  cp src/gui/images/tikzit.png "${APP_BUNDLE}/Contents/Resources/"
fi

# Run macdeployqt with dmg creation
echo "Running macdeployqt..."
macdeployqt "${APP_BUNDLE}" -verbose=2 -dmg

echo "Done — ${APP_NAME}.dmg created."
