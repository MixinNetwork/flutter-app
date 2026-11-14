#!/bin/sh

# Re-sign a built Mixin.app with a distribution identity.
#
# usage: macos_sign.sh <app> <identity> <entitlements> [provisioning_profile]
#
# Nested code is signed first, deepest paths first, then the app itself with
# the entitlements. Pass a provisioning profile for Mac App Store builds.

set -eu

if [ $# -lt 3 ]; then
	echo "usage: $0 <app> <identity> <entitlements> [provisioning_profile]" >&2
	exit 1
fi

APP="$1"
IDENTITY="$2"
ENTITLEMENTS="$3"
PROFILE="${4:-}"

if [ ! -x "$APP/Contents/MacOS/Mixin" ]; then
	echo "error: invalid app bundle: $APP" >&2
	exit 1
fi

if [ -n "$PROFILE" ]; then
	cp "$PROFILE" "$APP/Contents/embedded.provisionprofile"
fi

sign() {
	codesign --force --timestamp --options runtime --sign "$IDENTITY" "$@"
}

# Sparkle, when dist/macos_sparkle.sh added it, is signed here in its own
# order: Downloader.xpc keeps its entitlements, Autoupdate is an executable
# and not a bundle, and the sandboxed app may then look up the installer
# services of Sparkle.
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE" ]; then
	sign "$SPARKLE/Versions/B/XPCServices/Installer.xpc"
	sign --preserve-metadata=entitlements "$SPARKLE/Versions/B/XPCServices/Downloader.xpc"
	sign "$SPARKLE/Versions/B/Autoupdate"
	sign "$SPARKLE/Versions/B/Updater.app"
	sign "$SPARKLE"

	ID="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Contents/Info.plist")"
	APP_ENTITLEMENTS="$(mktemp)"
	trap 'rm -f "$APP_ENTITLEMENTS"' EXIT
	cp "$ENTITLEMENTS" "$APP_ENTITLEMENTS"
	KEY=com.apple.security.temporary-exception.mach-lookup.global-name
	/usr/libexec/PlistBuddy -c "Add :$KEY array" \
		-c "Add :$KEY:0 string $ID-spks" -c "Add :$KEY:1 string $ID-spki" \
		"$APP_ENTITLEMENTS"
	ENTITLEMENTS="$APP_ENTITLEMENTS"
fi

find "$APP/Contents" -depth \( -name "*.framework" -o -name "*.dylib" -o -name "*.xpc" -o -name "*.app" \) |
	while IFS= read -r item; do
		case "$item" in
		"$SPARKLE" | "$SPARKLE"/*) ;;
		*) sign "$item" ;;
		esac
	done

sign --entitlements "$ENTITLEMENTS" "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
