#!/usr/bin/env bash
set -euo pipefail

# Downloads the official Android "platform-tools" package for macOS and
# copies `adb` into the destination directory so it can be embedded inside
# the app bundle. This lets DroidFinder run on machines that don't have
# adb (Android Platform Tools) installed system-wide.
#
# Usage: fetch_platform_tools.sh <destination-dir>
#
# Network failures are non-fatal: if adb can't be downloaded (and isn't
# already cached from a previous run), the build simply continues without
# a bundled adb, and DroidFinder falls back to any adb found on the system.

DEST_DIR="${1:?Usage: fetch_platform_tools.sh <destination-dir>}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="$ROOT_DIR/build/platform-tools-cache"
ZIP_PATH="$CACHE_DIR/platform-tools-latest-darwin.zip"
PLATFORM_TOOLS_URL="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"

mkdir -p "$CACHE_DIR" "$DEST_DIR"

if [[ ! -x "$CACHE_DIR/platform-tools/adb" ]]; then
  echo "Fetching Android platform-tools for bundling…"
  if curl -fsSL -o "$ZIP_PATH" "$PLATFORM_TOOLS_URL"; then
    rm -rf "$CACHE_DIR/platform-tools"
    unzip -q -o "$ZIP_PATH" -d "$CACHE_DIR"
  else
    echo "warning: could not download platform-tools; adb will not be bundled (DroidFinder will fall back to a system-installed adb at runtime)." >&2
    exit 0
  fi
fi

if [[ -x "$CACHE_DIR/platform-tools/adb" ]]; then
  cp "$CACHE_DIR/platform-tools/adb" "$DEST_DIR/adb"
  chmod +x "$DEST_DIR/adb"
  echo "Bundled adb at: $DEST_DIR/adb"
else
  echo "warning: adb binary not found after extracting platform-tools; skipping bundling." >&2
fi
