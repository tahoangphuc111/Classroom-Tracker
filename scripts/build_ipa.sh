#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "===> [iOS] Archiving Classroom Tracker iOS Release (iOS 17 -> 27)..."
mkdir -p build

if command -v xcodegen >/dev/null 2>&1; then
  echo "===> [iOS] Synchronizing Xcode project with project.yml..."
  xcodegen generate
fi

# Ensure Xcode 15/14 compatibility (objectVersion 56)
if [ -f "ClassroomTracker.xcodeproj/project.pbxproj" ]; then
  sed -i '' 's/objectVersion = [0-9]*/objectVersion = 56/' ClassroomTracker.xcodeproj/project.pbxproj 2>/dev/null || true
fi

if [ -f "$ROOT_DIR/scripts/inject_env.sh" ]; then
  trap '"$ROOT_DIR/scripts/inject_env.sh" restore' EXIT INT TERM
  "$ROOT_DIR/scripts/inject_env.sh" apply
fi

xcodebuild -project ClassroomTracker.xcodeproj \
  -scheme ClassroomApp-iOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$ROOT_DIR/build/DerivedData-IPA" \
  -archivePath "$ROOT_DIR/build/iOSArchive.xcarchive" \
  IPHONEOS_DEPLOYMENT_TARGET="17.0" \
  archive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

echo "===> [iOS] Packaging into ClassroomTracker.ipa..."
rm -rf "$ROOT_DIR/build/Payload"
mkdir -p "$ROOT_DIR/build/Payload"
APP_PATH="$ROOT_DIR/build/Payload/Classroom Tracker.app"
cp -R "$ROOT_DIR/build/iOSArchive.xcarchive/Products/Applications/Classroom Tracker.app" "$APP_PATH"

# Embed App Groups so the installer can provision them when it re-signs the IPA.
sign_for_packaging() {
  local bundle_path="$1"
  local source_entitlements="$2"
  local packaging_entitlements="$ROOT_DIR/build/$(basename "$source_entitlements")"

  # The keychain group contains a signing-team placeholder from the Xcode build.
  plutil -remove keychain-access-groups -o "$packaging_entitlements" "$source_entitlements"
  codesign --force --sign - --generate-entitlement-der --entitlements "$packaging_entitlements" "$bundle_path"
}

sign_for_packaging "$APP_PATH/PlugIns/Classroom Deadlines.appex" "$ROOT_DIR/ClassroomWidget/ClassroomWidget.iOS.entitlements"
sign_for_packaging "$APP_PATH" "$ROOT_DIR/ClassroomApp/ClassroomApp.iOS.entitlements"
codesign --verify --deep --strict "$APP_PATH"

cd "$ROOT_DIR/build"
rm -f ClassroomTracker.new.ipa
zip -q -r -y ClassroomTracker.new.ipa Payload
mv -f ClassroomTracker.new.ipa "$ROOT_DIR/ClassroomTracker.ipa"
cd "$ROOT_DIR"

echo "===> [iOS] Successfully created $ROOT_DIR/ClassroomTracker.ipa"
