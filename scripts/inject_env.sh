#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION="${1:-apply}"

export SWIFT_FILE="$ROOT_DIR/Shared/Network/GoogleOAuthService.swift"
export KT_MANAGER_FILE="$ROOT_DIR/android/app/src/main/java/com/phucta/classroom/data/remote/GoogleOAuthManager.kt"
export KT_PREFS_FILE="$ROOT_DIR/android/app/src/main/java/com/phucta/classroom/data/local/ClassroomPreferences.kt"
export IOS_INFO_PLIST="$ROOT_DIR/ClassroomApp/Info-iOS.plist"
export MAC_INFO_PLIST="$ROOT_DIR/ClassroomApp/Info.plist"
export ANDROID_MANIFEST="$ROOT_DIR/android/app/src/main/AndroidManifest.xml"

config_files=("$SWIFT_FILE" "$KT_MANAGER_FILE" "$KT_PREFS_FILE" "$IOS_INFO_PLIST" "$MAC_INFO_PLIST" "$ANDROID_MANIFEST")

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
  local file
  for file in "${config_files[@]}"; do
    if [ -f "$file.bak" ]; then
      mv -f "$file.bak" "$file"
    fi
  done
}

apply_env() {
  load_env

  if [ -z "$CLIENT_SECRET" ] && [ -z "$CLIENT_ID" ]; then
    return 0
  fi

  if [[ -n "$CLIENT_ID" && ! "$CLIENT_ID" =~ ^[a-z0-9-]+\.apps\.googleusercontent\.com$ ]]; then
    echo "Invalid Google OAuth client ID." >&2
    return 1
  fi
  local file
  for file in "${config_files[@]}"; do
    if [ -f "$file" ] && [ ! -f "$file.bak" ]; then
      cp "$file" "$file.bak"
    fi
  done

  export INJECT_CLIENT_SECRET="$CLIENT_SECRET"
  export INJECT_CLIENT_ID="$CLIENT_ID"

  python3 -c '
from copy import deepcopy
from pathlib import Path
import os
import plistlib
import re
import xml.etree.ElementTree as ET

secret = os.environ.get("INJECT_CLIENT_SECRET", "")
client_id = os.environ.get("INJECT_CLIENT_ID", "")
mask = 0x5A

if client_id:
    scheme = ".".join(reversed(client_id.split(".")))
    for key in ("IOS_INFO_PLIST", "MAC_INFO_PLIST"):
        path = Path(os.environ[key])
        if path.is_file():
            info = plistlib.loads(path.read_bytes())
            types = info.setdefault("CFBundleURLTypes", [])
            if not any(scheme in entry.get("CFBundleURLSchemes", []) for entry in types):
                types.append({"CFBundleURLName": scheme, "CFBundleURLSchemes": [scheme]})
                path.write_bytes(plistlib.dumps(info, sort_keys=False))

    manifest_path = Path(os.environ["ANDROID_MANIFEST"])
    if manifest_path.is_file():
        namespace = "http://schemas.android.com/apk/res/android"
        ET.register_namespace("android", namespace)
        attrs = "{" + namespace + "}"
        parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
        manifest = ET.parse(manifest_path, parser=parser)
        activity = next(node for node in manifest.findall("./application/activity")
                        if node.get(attrs + "name") == ".ui.MainActivity")
        schemes = activity.findall("./intent-filter/data")
        if not any(node.get(attrs + "scheme") == scheme for node in schemes):
            template = next(node for node in activity.findall("intent-filter")
                            if any(data.get(attrs + "scheme", "").startswith("com.googleusercontent.apps.")
                                   for data in node.findall("data")))
            callback = deepcopy(template)
            callback.find("data").set(attrs + "scheme", scheme)
            activity.append(callback)
            ET.indent(manifest, space="    ")
            manifest.write(manifest_path, encoding="utf-8", xml_declaration=True)

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
