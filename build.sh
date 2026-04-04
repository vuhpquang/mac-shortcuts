#!/usr/bin/env bash
# build.sh
# This script builds GestureKit, signs it, packages it into a DMG, and notarizes it.
#
# What it does, step by step:
#   1. Compiles GestureKit from source using xcodebuild
#   2. Creates a .xcarchive (a build snapshot used for distribution)
#   3. Exports the signed .app from the archive
#   4. Creates a DMG installer file (the kind you download and drag to Applications)
#   5. Submits the DMG to Apple for notarization (required for macOS Gatekeeper)
#   6. Attaches ("staples") the notarization ticket to the DMG
#
# REQUIREMENTS before running:
#   - Xcode + Command Line Tools installed
#   - A valid "Developer ID Application" certificate in your Keychain
#   - An Apple Developer account with notarization credentials set up
#   - xcrun notarytool credentials stored in Keychain (see README for instructions)
#
# USAGE:
#   chmod +x build.sh      # (already done by git) Make the script executable
#   ./build.sh             # Run the build

# Exit immediately if any command fails.
# This prevents partial builds from silently continuing.
set -euo pipefail

# ─────────────────────────────────────────────────────────
# CONFIGURATION — update these for your signing identity
# ─────────────────────────────────────────────────────────

# Your Developer ID Application certificate name (shown in Keychain Access).
# Example: "Developer ID Application: Jane Smith (TEAM12345)"
DEVELOPER_ID="${DEVELOPER_ID:-Developer ID Application: YOUR NAME (TEAMID)}"

# Your Apple ID email and App-Specific Password for notarization.
# Store these in Keychain using:
#   xcrun notarytool store-credentials "GestureKit" \
#     --apple-id "you@example.com" \
#     --team-id "TEAMID" \
#     --password "xxxx-xxxx-xxxx-xxxx"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-GestureKit}"

# Build output directory (relative to this script's location).
BUILD_DIR="$(pwd)/build"

# App and archive names.
SCHEME="GestureKit"
ARCHIVE_PATH="$BUILD_DIR/$SCHEME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_PATH="$EXPORT_PATH/$SCHEME.app"
DMG_PATH="$BUILD_DIR/$SCHEME.dmg"

# ─────────────────────────────────────────────────────────
# STEP 0: Clean and create build directory
# ─────────────────────────────────────────────────────────

echo "==> Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ─────────────────────────────────────────────────────────
# STEP 1: Archive the app
# Archives are like "frozen builds" — a snapshot of the compiled app
# in a format ready for export and signing.
# ─────────────────────────────────────────────────────────

echo "==> Archiving $SCHEME..."
xcodebuild \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "==> Archive created at: $ARCHIVE_PATH"

# ─────────────────────────────────────────────────────────
# STEP 2: Create ExportOptions.plist
# This tells xcodebuild how to export the app for distribution:
# "Developer ID" = outside the App Store, for direct download.
# ─────────────────────────────────────────────────────────

EXPORT_OPTIONS_PLIST="$BUILD_DIR/ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>TEAMID</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

# ─────────────────────────────────────────────────────────
# STEP 3: Export the signed .app from the archive
# ─────────────────────────────────────────────────────────

echo "==> Exporting signed app..."
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "==> App exported to: $APP_PATH"

# ─────────────────────────────────────────────────────────
# STEP 4: Additional code signing (belt-and-suspenders)
# Ensures the app bundle is properly signed before packaging.
# ─────────────────────────────────────────────────────────

echo "==> Verifying code signature..."
codesign --deep --force --verify --sign "$DEVELOPER_ID" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "==> Code signature verified."

# ─────────────────────────────────────────────────────────
# STEP 5: Create the DMG installer
#
# A DMG (Disk Image) is the standard macOS way to distribute apps.
# Users download it, double-click to mount it, and drag the app to Applications.
# We create a temporary read-write DMG, add the app + an Applications symlink,
# then convert it to a compressed read-only DMG for distribution.
# ─────────────────────────────────────────────────────────

echo "==> Creating DMG..."

TEMP_DMG="$BUILD_DIR/tmp_$SCHEME.dmg"
MOUNT_DIR="$BUILD_DIR/dmg_mount"

# Create a read-write DMG.
hdiutil create \
    -size 50m \
    -volname "$SCHEME" \
    -fs HFS+ \
    -srcfolder "$APP_PATH" \
    -ov \
    "$TEMP_DMG"

# Mount the DMG so we can add the Applications symlink.
hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_DIR" -noautoopen

# Add a symlink to /Applications inside the DMG.
# This gives users the familiar "drag here to install" affordance.
ln -s /Applications "$MOUNT_DIR/Applications"

# Unmount the DMG.
hdiutil detach "$MOUNT_DIR"

# Convert the read-write DMG to a compressed read-only DMG for distribution.
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"

# Clean up the temporary DMG.
rm -f "$TEMP_DMG"

echo "==> DMG created at: $DMG_PATH"

# ─────────────────────────────────────────────────────────
# STEP 6: Notarize the DMG
#
# Notarization is Apple's process of checking your app for malware before
# letting it run on other people's Macs. Without it, macOS shows a scary
# "can't be opened because Apple cannot check it for malicious software" warning.
# ─────────────────────────────────────────────────────────

echo "==> Submitting DMG for notarization (this may take a few minutes)..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARYTOOL_PROFILE" \
    --wait

echo "==> Notarization complete."

# ─────────────────────────────────────────────────────────
# STEP 7: Staple the notarization ticket
#
# "Stapling" attaches the notarization result directly to the DMG file
# so Gatekeeper can verify it offline (without an internet connection).
# ─────────────────────────────────────────────────────────

echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo ""
echo "======================================================"
echo "  Build complete!"
echo "  Output: $DMG_PATH"
echo "======================================================"
