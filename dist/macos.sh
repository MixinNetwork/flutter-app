#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE_APP="$SCRIPT_DIR/Mixin.app"
DMG_PATH="$SCRIPT_DIR/mixin.dmg"
APPDMG_CONFIG="$SCRIPT_DIR/appdmg.json"

if command -v appdmg >/dev/null 2>&1; then
	APPDMG_CMD="appdmg"
elif command -v npx >/dev/null 2>&1; then
	APPDMG_CMD="npx --yes appdmg"
else
	echo "error: neither appdmg nor npx found" >&2
	echo "hint: install appdmg globally, or install Node.js/npm for npx" >&2
	exit 1
fi

if [ ! -d "$SOURCE_APP" ]; then
	echo "error: source app not found: $SOURCE_APP" >&2
	echo "hint: place your signed app at dist/Mixin.app first" >&2
	exit 1
fi

if [ ! -x "$SOURCE_APP/Contents/MacOS/Mixin" ]; then
	echo "error: invalid app bundle, executable missing: $SOURCE_APP/Contents/MacOS/Mixin" >&2
	exit 1
fi

if command -v xattr >/dev/null 2>&1; then
	xattr -dr com.apple.quarantine "$SOURCE_APP" 2>/dev/null || true
fi

rm -f "$DMG_PATH"
cd "$SCRIPT_DIR"
$APPDMG_CMD "$APPDMG_CONFIG" "$DMG_PATH"
