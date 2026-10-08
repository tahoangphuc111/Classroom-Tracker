#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/android"

if [ -d "/opt/homebrew/opt/openjdk@17" ]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
  export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
fi

echo "===> [Android] Building Release APK..."
chmod +x ./gradlew
./gradlew assembleRelease

APK_SRC="$(find app/build/outputs/apk/release -name "*.apk" | head -n 1)"
if [ -n "$APK_SRC" ] && [ -f "$APK_SRC" ]; then
  cp "$APK_SRC" "$ROOT_DIR/ClassroomTracker.apk"
  echo "===> [Android] Successfully created $ROOT_DIR/ClassroomTracker.apk"
else
  echo "ERROR: Release APK not found in app/build/outputs/apk/release" >&2
  exit 1
fi
