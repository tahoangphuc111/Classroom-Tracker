#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION="${1:-apply}"

export SWIFT_FILE="$ROOT_DIR/Shared/Network/GoogleOAuthService.swift"
export SWIFT_BAK="$ROOT_DIR/Shared/Network/GoogleOAuthService.swift.bak"

export KT_MANAGER_FILE="$ROOT_DIR/android/app/src/main/java/com/phucta/classroom/data/remote/GoogleOAuthManager.kt"
export KT_MANAGER_BAK="$ROOT_DIR/android/app/src/main/java/com/phucta/classroom/data/remote/GoogleOAuthManager.kt.bak"

export KT_PREFS_FILE="$ROOT_DIR/android/app/src/main/java/com/phucta/classroom/data/local/ClassroomPreferences.kt"
export KT_PREFS_BAK="$ROOT_DIR/android/app/src/main/java/com/phucta/classroom/data/local/ClassroomPreferences.kt.bak"

load_env() {
  ENV_SECRET=""
  ENV_CLIENT_ID=""

  if [ -f "$ROOT_DIR/.env" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
      fi
      if [[ "$line" =~ ^export[[:space:]]+ ]]; then
        line="${line#export }"
      fi
      key="${line%%=*}"
      val="${line#*=}"
      key="$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      val="$(echo "$val" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      if [[ "$val" =~ ^\"(.*)\"$ ]]; then
        val="${BASH_REMATCH[1]}"
      elif [[ "$val" =~ ^\'(.*)\'$ ]]; then
        val="${BASH_REMATCH[1]}"
      fi
      if [ -n "$key" ]; then
        case "$key" in
          GOOGLE_OAUTH_CLIENT_SECRET|OAUTH_CLIENT_SECRET|CLIENT_SECRET|SECRET_ID|GOOGLE_CLIENT_SECRET)
            ENV_SECRET="$val"
            ;;
          GOOGLE_OAUTH_CLIENT_ID|OAUTH_CLIENT_ID|CLIENT_ID|GOOGLE_CLIENT_ID)
            ENV_CLIENT_ID="$val"
            ;;
        esac
      fi
    done < "$ROOT_DIR/.env"
  fi

  PARENT_SECRET="${GOOGLE_OAUTH_CLIENT_SECRET:-${OAUTH_CLIENT_SECRET:-${CLIENT_SECRET:-${SECRET_ID:-${GOOGLE_CLIENT_SECRET:-}}}}}"
  PARENT_CLIENT_ID="${GOOGLE_OAUTH_CLIENT_ID:-${OAUTH_CLIENT_ID:-${CLIENT_ID:-${GOOGLE_CLIENT_ID:-}}}}"

  CLIENT_SECRET="${PARENT_SECRET:-$ENV_SECRET}"
  CLIENT_ID="${PARENT_CLIENT_ID:-$ENV_CLIENT_ID}"

  if [ "$CLIENT_SECRET" = "YOUR_CLIENT_SECRET_HERE" ]; then
    CLIENT_SECRET=""
  fi
}

restore_files() {
  if [ -f "$SWIFT_BAK" ]; then
    mv -f "$SWIFT_BAK" "$SWIFT_FILE"
  fi
  if [ -f "$KT_MANAGER_BAK" ]; then
    mv -f "$KT_MANAGER_BAK" "$KT_MANAGER_FILE"
  fi
  if [ -f "$KT_PREFS_BAK" ]; then
    mv -f "$KT_PREFS_BAK" "$KT_PREFS_FILE"
  fi
}

apply_env() {
  load_env

  if [ -z "$CLIENT_SECRET" ] && [ -z "$CLIENT_ID" ]; then
    return 0
  fi

  if [ -f "$SWIFT_FILE" ] && [ ! -f "$SWIFT_BAK" ]; then
    cp "$SWIFT_FILE" "$SWIFT_BAK"
  fi
  if [ -f "$KT_MANAGER_FILE" ] && [ ! -f "$KT_MANAGER_BAK" ]; then
    cp "$KT_MANAGER_FILE" "$KT_MANAGER_BAK"
  fi
  if [ -f "$KT_PREFS_FILE" ] && [ ! -f "$KT_PREFS_BAK" ]; then
    cp "$KT_PREFS_FILE" "$KT_PREFS_BAK"
  fi

  export INJECT_CLIENT_SECRET="$CLIENT_SECRET"
  export INJECT_CLIENT_ID="$CLIENT_ID"

  python3 -c '
import os
import re

secret = os.environ.get("INJECT_CLIENT_SECRET", "")
client_id = os.environ.get("INJECT_CLIENT_ID", "")
mask = 0x5A

swift_path = os.environ.get("SWIFT_FILE", "")
if swift_path and os.path.exists(swift_path):
    with open(swift_path, "r", encoding="utf-8") as f:
        content = f.read()

    if secret:
        bytes_list = [str(b ^ mask) for b in secret.encode("utf-8")]
        swift_bytes = "[" + ", ".join(bytes_list) + "]"
        content = content.replace("bundledSecretObfuscatedBytes: [UInt8] = []", f"bundledSecretObfuscatedBytes: [UInt8] = {swift_bytes}")

    if client_id:
        content = re.sub(r"bundledClientId = \"[^\"]*\"", f"bundledClientId = \"{client_id}\"", content)

    with open(swift_path, "w", encoding="utf-8") as f:
        f.write(content)

kt_mgr_path = os.environ.get("KT_MANAGER_FILE", "")
if kt_mgr_path and os.path.exists(kt_mgr_path) and secret:
    bytes_list = [f"{(b ^ mask) if (b ^ mask) < 128 else (b ^ mask) - 256}.toByte()" for b in secret.encode("utf-8")]
    kotlin_bytes = "byteArrayOf(" + ", ".join(bytes_list) + ")"
    with open(kt_mgr_path, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("BUNDLED_SECRET_OBFUSCATED: ByteArray = byteArrayOf()", f"BUNDLED_SECRET_OBFUSCATED: ByteArray = {kotlin_bytes}")
    with open(kt_mgr_path, "w", encoding="utf-8") as f:
        f.write(content)

kt_prefs_path = os.environ.get("KT_PREFS_FILE", "")
if kt_prefs_path and os.path.exists(kt_prefs_path) and client_id:
    with open(kt_prefs_path, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r"BUNDLED_CLIENT_ID = \"[^\"]*\"", f"BUNDLED_CLIENT_ID = \"{client_id}\"", content)
    with open(kt_prefs_path, "w", encoding="utf-8") as f:
        f.write(content)
'
}

case "$ACTION" in
  apply)
    apply_env
    ;;
  restore)
    restore_files
    ;;
  run)
    shift
    trap restore_files EXIT INT TERM
    apply_env
    "$@"
    ;;
  *)
    echo "Usage: $0 {apply|restore|run <command...>}"
    exit 1
    ;;
esac
