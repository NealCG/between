#!/bin/bash
# Builds Between.app (menu bar only, no Dock icon) into this folder.
set -euo pipefail
cd "$(dirname "$0")"

# UNIVERSAL=1 builds one app that runs on both Apple Silicon and Intel Macs (needs full Xcode).
# VERSION sets the version number shown in Finder (defaults to 0.1).
VERSION="${VERSION:-0.1}"
ARCHS=()
if [ "${UNIVERSAL:-0}" = "1" ]; then ARCHS=(--arch arm64 --arch x86_64); fi

swift build -c release ${ARCHS[@]+"${ARCHS[@]}"}
BIN="$(swift build -c release ${ARCHS[@]+"${ARCHS[@]}"} --show-bin-path)/Between"

APP="Between.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Between"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Between</string>
  <key>CFBundleDisplayName</key><string>Between</string>
  <key>CFBundleIdentifier</key><string>com.between.breath</string>
  <key>CFBundleExecutable</key><string>Between</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>__VERSION__</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

sed -i '' "s/__VERSION__/$VERSION/" "$APP/Contents/Info.plist"

# Ad-hoc signature so macOS will run it locally and allow "Open at login".
codesign --force --deep --sign - "$APP"

# A zip that keeps the app intact, ready to send to friends.
rm -f Between.zip
ditto -c -k --keepParent "$APP" Between.zip

echo "Built $(pwd)/$APP and Between.zip"
echo "Drag it into /Applications, then open it. Look for the wheel icon in the menu bar."
