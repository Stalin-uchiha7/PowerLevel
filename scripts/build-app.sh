#!/usr/bin/env bash
# Builds build/PowerLevel.app (menu-bar only, ad-hoc signed).
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="build/PowerLevel.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/PowerLevel "$APP/Contents/MacOS/PowerLevel"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>PowerLevel</string>
    <key>CFBundleDisplayName</key><string>Power Level</string>
    <key>CFBundleIdentifier</key><string>dev.powerlevel.app</string>
    <key>CFBundleExecutable</key><string>PowerLevel</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP  ->  open $APP"
