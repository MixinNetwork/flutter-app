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

find "$APP/Contents" -depth \( -name "*.framework" -o -name "*.dylib" -o -name "*.xpc" -o -name "*.app" \) |
	while IFS= read -r item; do
		sign "$item"
	done

sign --entitlements "$ENTITLEMENTS" "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
