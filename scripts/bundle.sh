#!/bin/sh
# Builds LifemartBar.app into ./build without Xcode.
set -eu

cd "$(dirname "$0")/.."
swift build -c release

app="build/LifemartBar.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/LifemartBar "$app/Contents/MacOS/"

cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>LifemartBar</string>
    <key>CFBundleIdentifier</key><string>io.github.onnya.lifemartbar</string>
    <key>CFBundleExecutable</key><string>LifemartBar</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$app"
echo "Built $app"
