#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "Classroom Tracker - Multiplatform Builder"
echo "=========================================="

"$ROOT_DIR/scripts/build_pkg.sh"
"$ROOT_DIR/scripts/build_ipa.sh"

if [ -d "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
elif [ -d "/opt/homebrew/opt/openjdk@17" ]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

if command -v java >/dev/null 2>&1; then
  JAVA_VER="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)"
  if [ "$JAVA_VER" -le 21 ] 2>/dev/null; then
    "$ROOT_DIR/scripts/build_apk.sh"
  else
    echo "===> [Android] Skipped local APK build: installed Java version is $JAVA_VER (Gradle/AGP requires Java <= 21). CI will build APK automatically."
  fi
else
  echo "===> [Android] Java not found, skipping local APK build. CI will build APK automatically."
fi

echo "=========================================="
echo "Artifacts generated:"
ls -lh "$ROOT_DIR"/ClassroomTracker.* 2>/dev/null || true
echo "=========================================="
