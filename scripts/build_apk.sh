#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/android"

if [ -f "$ROOT_DIR/scripts/inject_env.sh" ]; then
  "$ROOT_DIR/scripts/inject_env.sh" apply
  trap '"$ROOT_DIR/scripts/inject_env.sh" restore' EXIT INT TERM
fi

if [ -d "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
elif [ -d "/opt/homebrew/opt/openjdk@17" ]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
  export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
fi

# Ensure signing keystore is present for release build
if [ -z "${KEYSTORE_FILE:-}" ] || [ ! -f "${KEYSTORE_FILE:-}" ]; then
  FALLBACK_KEYSTORE="$ROOT_DIR/android/debug.keystore"
  if [ ! -f "$FALLBACK_KEYSTORE" ]; then
    echo "===> [Android] Generating self-signed keystore for release build..."
    keytool -genkeypair -v \
      -keystore "$FALLBACK_KEYSTORE" \
      -alias androiddebugkey \
      -keyalg RSA \
      -keysize 2048 \
      -validity 10000 \
      -storepass android \
      -keypass android \
      -dname "CN=Android Debug,O=Android,C=US"
  fi
  export KEYSTORE_FILE="$FALLBACK_KEYSTORE"
  export KEYSTORE_PASSWORD="android"
  export KEY_ALIAS="androiddebugkey"
  export KEY_PASSWORD="android"
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
