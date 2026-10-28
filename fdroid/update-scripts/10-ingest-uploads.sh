#!/usr/bin/env bash
set -euo pipefail

APP_ROOT=/fdroid
REPO_DIR="$APP_ROOT/repo"
METADATA_DIR="$APP_ROOT/metadata"
UPDATES_DIR=/updates

mkdir -p "$REPO_DIR" "$METADATA_DIR"

apk_target_name() {
  local apk="$1" name="" code="" aapt
  for aapt in aapt "$(ls /opt/android-sdk/build-tools/*/aapt 2>/dev/null | sort -V | tail -n1)"; do
    [ -n "$aapt" ] || continue
    command -v "$aapt" >/dev/null 2>&1 || [ -x "$aapt" ] || continue
    local badging
    badging=$("$aapt" dump badging "$apk" 2>/dev/null) || continue
    name=$(printf '%s\n' "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n1)
    code=$(printf '%s\n' "$badging" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p" | head -n1)
    [ -n "$name" ] && [ -n "$code" ] && break
    name=""; code=""
  done
  if [ -n "$name" ] && [ -n "$code" ]; then
    printf '%s_%s.apk' "$name" "$code"
  else
    basename "$apk"
  fi
}

shopt -s nullglob
apks=("$UPDATES_DIR"/*.apk)
if [ ${#apks[@]} -eq 0 ]; then
  echo "fdroid-ingest: no APKs in $UPDATES_DIR"
  exit 0
fi

for apk in "${apks[@]}"; do
  target=$(apk_target_name "$apk")
  echo "fdroid-ingest: moving $(basename "$apk") into repo as $target"
  cp -f "$apk" "$REPO_DIR/$target"
  rm -f "$apk"
done

cd "$APP_ROOT"
fdroid update --create-metadata --quiet || {
  echo "fdroid-ingest: --create-metadata reported a problem; continuing" >&2
}

echo "fdroid-ingest: done"
