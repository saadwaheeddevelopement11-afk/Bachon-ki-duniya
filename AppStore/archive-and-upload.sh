#!/bin/bash
# Archive + upload Kido to CMPAK App Store Connect.
# Prerequisites:
# 1) CMPAK Admin (or App ID com.cmpak.kidoApp already registered)
# 2) App record created in App Store Connect for com.cmpak.kidoApp
# 3) CMPAK Apple ID signed into Xcode → Settings → Accounts

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ARCHIVE_PATH="$ROOT/build/CmpakArchive.xcarchive"
EXPORT_PATH="$ROOT/build/CmpakExport"
EXPORT_OPTIONS="$ROOT/AppStore/ExportOptions-AppStore.plist"

echo "==> Archiving (team JVHLZ8B94A, bundle com.cmpak.kidoApp)..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
xcodebuild \
  -workspace "Bachon ki duniya.xcworkspace" \
  -scheme "Bachon ki duniya" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=JVHLZ8B94A \
  PRODUCT_BUNDLE_IDENTIFIER=com.cmpak.kidoApp \
  archive

echo "==> Exporting / uploading to App Store Connect..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_PATH" \
  -allowProvisioningUpdates

echo "==> Done. Check App Store Connect → TestFlight / Activity for the build."
