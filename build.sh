#!/usr/bin/env bash
# build.sh
# This script builds GestureKit (an SPM-based macOS app), signs the binary,
# packages it into a DMG, and optionally submits it for notarization.
#
# What it does, step by step:
#   1. Compiles GestureKit as a universal binary (Apple Silicon + Intel) using `swift build`
#   2. Code-signs the compiled binary with your Developer ID certificate
#   3. Creates a DMG installer file (the kind you download and drag to Applications)
#   4. Optionally submits the DMG to Apple for notarization (set NOTARIZE=1 to enable)
#   5. Optionally attaches ("staples") the notarization ticket to the DMG
#
# REQUIREMENTS before running:
#   - Swift toolchain (comes with Xcode or Command Line Tools)
#   - A valid "Developer ID Application" certificate in your Keychain
#   - For notarization: an Apple Developer account with xcrun notarytool credentials
#     stored in Keychain (see README for setup instructions)
#
# USAGE:
#   chmod +x build.sh           # Make the script executable (already done by git)
#   ./build.sh                  # Build and package (no notarization)
#   NOTARIZE=1 ./build.sh       # Build, package, AND notarize
#
# ENVIRONMENT VARIABLES:
#   TEAM_ID            — Your Developer ID Application certificate name.
#                        Example: "Developer ID Application: Jane Smith (ABCD1234EF)"
#   NOTARIZE           — Set to 1 to submit the DMG for notarization after packaging.
#   NOTARYTOOL_PROFILE — Keychain profile name used by xcrun notarytool (default: GestureKit)

# Exit immediately if any command fails, if any variable is unset, or if a pipe fails.
# This prevents a broken build from silently continuing past errors.
set -euo pipefail

# ─────────────────────────────────────────────────────────
# CONFIGURATION — update TEAM_ID for your signing certificate
# ─────────────────────────────────────────────────────────

# Your full Developer ID Application certificate name as shown in Keychain Access.
# Override by passing it as an environment variable:
#   TEAM_ID="Developer ID Application: Jane Smith (ABCD1234EF)" ./build.sh
TEAM_ID="${TEAM_ID:-Developer ID Application: YOUR NAME (TEAMID)}"

# Keychain profile created with `xcrun notarytool store-credentials`.
# Only used when NOTARIZE=1.
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-GestureKit}"

# Whether to notarize after packaging (0 = skip, 1 = notarize).
NOTARIZE="${NOTARIZE:-0}"

# The name of the binary produced by `swift build`.
# This must match the executable target name in Package.swift.
BINARY_NAME="GestureKit"

# Where `swift build` places the universal Release binary when targeting both archs.
BINARY_PATH=".build/apple/Products/Release/${BINARY_NAME}"

# Directory where we stage files before creating the DMG, and where the DMG lands.
BUILD_DIR="$(pwd)/build"

# Final DMG output path.
DMG_PATH="${BUILD_DIR}/${BINARY_NAME}.dmg"

# ─────────────────────────────────────────────────────────
# STEP 0: Clean and prepare the build output directory
# ─────────────────────────────────────────────────────────

echo "==> Preparing build directory: ${BUILD_DIR}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# ─────────────────────────────────────────────────────────
# STEP 1: Compile a universal release binary with Swift PM
#
# `swift build -c release` compiles with optimizations.
# `--arch arm64 --arch x86_64` produces a "universal" (fat) binary that
# runs natively on both Apple Silicon Macs and older Intel Macs.
# The compiled binary is written to:
#   .build/apple/Products/Release/GestureKit
# ─────────────────────────────────────────────────────────

echo "==> Building universal release binary..."
swift build \
    -c release \
    --arch arm64 \
    --arch x86_64

# Verify the binary was actually produced before continuing.
if [[ ! -f "${BINARY_PATH}" ]]; then
    echo "ERROR: Expected binary not found at ${BINARY_PATH}" >&2
    exit 1
fi

echo "==> Build succeeded. Binary at: ${BINARY_PATH}"

# ─────────────────────────────────────────────────────────
# STEP 2: Code-sign the binary
#
# Code signing proves to macOS that the app came from a known developer
# and has not been tampered with. Without a valid Developer ID signature,
# Gatekeeper will block the app from running on other people's Macs.
#
# --deep   : Sign nested code (frameworks, helpers, etc.) recursively.
# --force  : Replace any existing signature (safe to run repeatedly).
# --sign   : The certificate identity to sign with (from Keychain).
# ─────────────────────────────────────────────────────────

echo "==> Code-signing binary with: ${TEAM_ID}"
codesign \
    --deep \
    --force \
    --sign "${TEAM_ID}" \
    "${BINARY_PATH}"

# Verify the signature looks correct before packaging.
echo "==> Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "${BINARY_PATH}"
echo "==> Code signature OK."

# ─────────────────────────────────────────────────────────
# STEP 3: Create the DMG installer
#
# A DMG (Disk Image) is the standard macOS distribution format.
# Users download it, double-click to mount it, then copy the app
# to /Applications (or anywhere they like).
#
# We build the DMG in two stages:
#   a) Create a temporary read-write DMG from a staging folder
#      that contains the signed binary and a symlink to /Applications.
#   b) Convert it to a compressed, read-only DMG for distribution.
# ─────────────────────────────────────────────────────────

echo "==> Staging DMG contents..."

# Create a staging folder; this becomes the DMG window's contents.
STAGING_DIR="${BUILD_DIR}/dmg_staging"
mkdir -p "${STAGING_DIR}"

# Copy the signed binary into the staging folder.
cp "${BINARY_PATH}" "${STAGING_DIR}/${BINARY_NAME}"

# Add a symlink so users can drag the binary to /Applications.
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Creating DMG from staging folder..."

TEMP_DMG="${BUILD_DIR}/tmp_${BINARY_NAME}.dmg"

# hdiutil create: build a compressed DMG directly from the staging folder.
#   -volname  : The volume name shown when the DMG is mounted.
#   -srcfolder: Folder whose contents populate the DMG.
#   -fs HFS+  : macOS extended filesystem (required for Gatekeeper / code signing attributes).
#   -format UDZO : zlib-compressed read-only image, suitable for distribution.
#   -ov       : Overwrite the output file if it already exists.
hdiutil create \
    -volname "${BINARY_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -fs HFS+ \
    -format UDZO \
    -ov \
    "${DMG_PATH}"

# Remove the temporary staging folder — the final DMG is self-contained.
rm -rf "${STAGING_DIR}"

echo "==> DMG created at: ${DMG_PATH}"

# ─────────────────────────────────────────────────────────
# STEP 4 (optional): Notarize the DMG
#
# Notarization is Apple's automated malware scan for apps distributed
# outside the App Store. Without it, macOS Gatekeeper shows a warning
# ("This app cannot be opened because Apple cannot check it for malicious
# software") on the user's first launch.
#
# Requires NOTARIZE=1 and a valid keychain profile set up with:
#   xcrun notarytool store-credentials "GestureKit" \
#     --apple-id "you@example.com" \
#     --team-id "TEAMID" \
#     --password "xxxx-xxxx-xxxx-xxxx"
#
# --wait : Block until Apple's servers return a result (pass/fail).
# ─────────────────────────────────────────────────────────

if [[ "${NOTARIZE}" == "1" ]]; then
    echo "==> Submitting DMG for notarization (this may take several minutes)..."
    xcrun notarytool submit "${DMG_PATH}" \
        --keychain-profile "${NOTARYTOOL_PROFILE}" \
        --wait
    echo "==> Notarization complete."

    # "Stapling" embeds the notarization ticket inside the DMG so that
    # Gatekeeper can verify it offline without an internet connection.
    echo "==> Stapling notarization ticket to DMG..."
    xcrun stapler staple "${DMG_PATH}"
    echo "==> Staple complete."
else
    echo "==> Notarization skipped (set NOTARIZE=1 to enable)."
fi

# ─────────────────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────────────────

echo ""
echo "======================================================"
echo "  Build complete!"
echo "  Output: ${DMG_PATH}"
echo "======================================================"
