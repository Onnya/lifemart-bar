#!/bin/sh
# Builds LifemartBar.app into ./build without Xcode.
set -eu

cd "$(dirname "$0")/.."
swift build -c release

app="build/LifemartBar.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/LifemartBar "$app/Contents/MacOS/"
cp Resources/AppIcon.icns "$app/Contents/Resources/"

cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>LifemartBar</string>
    <key>CFBundleIdentifier</key><string>io.github.onnya.lifemartbar</string>
    <key>CFBundleExecutable</key><string>LifemartBar</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

# Prefer the stable identity from make-signing-cert.sh; ad-hoc signatures
# change on every build and make the Keychain ask for the password again.
keychain="$HOME/Library/Keychains/lifemartbar-signing.keychain-db"
identity=""
if [ -f "$keychain" ]; then
    security unlock-keychain -p lifemartbar "$keychain"
    identity=$(security find-identity -p codesigning "$keychain" \
        | awk '/"LifemartBar Local Signing"/ { print $2; exit }')
fi

if [ -n "$identity" ]; then
    codesign --force --keychain "$keychain" --sign "$identity" "$app"
else
    echo "No local signing identity, signing ad-hoc (run scripts/make-signing-cert.sh once)"
    codesign --force --sign - "$app"
fi
echo "Built $app"
