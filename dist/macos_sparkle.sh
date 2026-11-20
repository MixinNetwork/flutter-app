#!/bin/sh
# Add Sparkle to the DMG build of Mixin.app, before dist/macos_sign.sh.
# The App Store build must not get it: the App Store forbids self-updaters.
# Usage: dist/macos_sparkle.sh <Mixin.app>

set -eu

APP="$1"
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
VERSION=2.10.1
SHA256=1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27
KEY="$(tr -d '[:space:]' < "$ROOT/assets/update_ed25519.pub")"

if [ -z "$KEY" ]; then
	echo "assets/update_ed25519.pub is empty: the DMG gets no updater"
	exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/sparkle.tar.xz" \
	"https://github.com/sparkle-project/Sparkle/releases/download/$VERSION/Sparkle-$VERSION.tar.xz"
echo "$SHA256  $TMP/sparkle.tar.xz" | shasum -a 256 -c -
tar -xJf "$TMP/sparkle.tar.xz" -C "$TMP" ./Sparkle.framework
rm -rf "$APP/Contents/Frameworks/Sparkle.framework"
ditto "$TMP/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"

PLIST="$APP/Contents/Info.plist"
for entry in "SUPublicEDKey string $KEY" \
	"SUEnableInstallerLauncherService bool true" \
	"SUEnableAutomaticChecks bool false"; do
	set -- $entry
	/usr/libexec/PlistBuddy -c "Delete :$1" "$PLIST" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$PLIST"
done
