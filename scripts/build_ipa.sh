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

xcodebuild -project ClassroomTracker.xcodeproj \
  -scheme ClassroomApp-iOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ROOT_DIR/build/iOSArchive.xcarchive" \
  IPHONEOS_DEPLOYMENT_TARGET="17.0" \
  archive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

echo "===> [iOS] Packaging into ClassroomTracker.ipa..."
rm -rf "$ROOT_DIR/build/Payload"
mkdir -p "$ROOT_DIR/build/Payload"
cp -R "$ROOT_DIR/build/iOSArchive.xcarchive/Products/Applications/Classroom Tracker.app" "$ROOT_DIR/build/Payload/"

cd "$ROOT_DIR/build"
zip -q -r -y "$ROOT_DIR/ClassroomTracker.ipa" Payload
cd "$ROOT_DIR"

echo "===> [iOS] Successfully created $ROOT_DIR/ClassroomTracker.ipa"
