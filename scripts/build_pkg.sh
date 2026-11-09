#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ -f "$ROOT_DIR/scripts/inject_env.sh" ]; then
  "$ROOT_DIR/scripts/inject_env.sh" apply
  trap '"$ROOT_DIR/scripts/inject_env.sh" restore' EXIT INT TERM
fi

echo "===> [macOS] Building Classroom Tracker Release for macOS 27..."
mkdir -p build/Release

# Detect environment SDK version
MAX_SDK=$(xcodebuild -showsdks | grep -o 'macosx[0-9]*' | sort -V | tail -n 1 | sed 's/macosx//' || echo "27")
if [ -n "$MAX_SDK" ] && [ "$MAX_SDK" -lt 27 ] 2>/dev/null; then
  echo "⚠️ Warning: Host Xcode max SDK is $MAX_SDK. Adjusting deployment target to $MAX_SDK.0 for runner compatibility."
  TARGET_VER="${MAX_SDK}.0"
else
  TARGET_VER="27.0"
fi

if command -v xcodegen >/dev/null 2>&1; then
  echo "===> [macOS] Synchronizing Xcode project with project.yml (Target: $TARGET_VER)..."
  xcodegen generate
fi

# Ensure Xcode 15/14 compatibility (objectVersion 56)
if [ -f "ClassroomTracker.xcodeproj/project.pbxproj" ]; then
  sed -i '' 's/objectVersion = [0-9]*/objectVersion = 56/' ClassroomTracker.xcodeproj/project.pbxproj 2>/dev/null || true
fi

SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep -E '^[[:space:]]*1\)' | head -n 1 | awk -F '"' '{print $2}' || true)

BUILT=0
if [ -n "$SIGN_IDENTITY" ]; then
  echo "===> [macOS] Attempting build with signing identity: $SIGN_IDENTITY"
  if xcodebuild -project ClassroomTracker.xcodeproj \
    -scheme ClassroomApp \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    CONFIGURATION_BUILD_DIR="$ROOT_DIR/build/Release" \
    MACOSX_DEPLOYMENT_TARGET="$TARGET_VER" \
    build; then
    BUILT=1
  else
    echo "⚠️ Signing with identity failed (likely missing matching provisioning profile). Falling back to ad-hoc signing..."
  fi
fi

if [ "$BUILT" -eq 0 ]; then
  echo "===> [macOS] Building with ad-hoc signing..."
  xcodebuild -project ClassroomTracker.xcodeproj \
    -scheme ClassroomApp \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    CONFIGURATION_BUILD_DIR="$ROOT_DIR/build/Release" \
    MACOSX_DEPLOYMENT_TARGET="$TARGET_VER" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build
fi

echo "===> [macOS] Packaging into ClassroomTracker.pkg..."
pkgbuild --component "$ROOT_DIR/build/Release/Classroom Tracker.app" \
  --install-location "/Applications" \
  "$ROOT_DIR/ClassroomTracker.pkg"

echo "===> [macOS] Successfully created $ROOT_DIR/ClassroomTracker.pkg (macOS $TARGET_VER)"
