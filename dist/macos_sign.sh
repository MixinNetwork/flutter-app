#!/bin/sh
# Sign Mixin.app inside-out with the hardened runtime, for notarization.
# Usage: dist/macos_sign.sh <Mixin.app> <identity>   ("-" signs ad-hoc)

set -eu

APP="$1"
IDENTITY="$2"
ENTITLEMENTS="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/macos/Runner/Release.entitlements"

if [ "$IDENTITY" = "-" ]; then
	TIMESTAMP="--timestamp=none"
else
	TIMESTAMP="--timestamp"
fi

sign() {
	codesign --force --sign "$IDENTITY" --options runtime "$TIMESTAMP" "$@"
}

# Sparkle, when dist/macos_sparkle.sh added it: its helpers are signed first,
# and the sandboxed app may then look up its installer services.
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
if [ -d "$SPARKLE" ]; then
	sign "$SPARKLE/XPCServices/Installer.xpc"
	sign --preserve-metadata=entitlements "$SPARKLE/XPCServices/Downloader.xpc"
	sign "$SPARKLE/Autoupdate"
	sign "$SPARKLE/Updater.app"
	ID="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Contents/Info.plist")"
	DMG_ENTITLEMENTS="$(mktemp)"
	trap 'rm -f "$DMG_ENTITLEMENTS"' EXIT
	cp "$ENTITLEMENTS" "$DMG_ENTITLEMENTS"
	KEY=com.apple.security.temporary-exception.mach-lookup.global-name
	/usr/libexec/PlistBuddy -c "Add :$KEY array" \
		-c "Add :$KEY:0 string $ID-spks" -c "Add :$KEY:1 string $ID-spki" \
		"$DMG_ENTITLEMENTS"
	if [ "$IDENTITY" = "-" ]; then
		# An ad-hoc signature has no Team ID, so library validation rejects Sparkle.
		/usr/libexec/PlistBuddy -c "Add :com.apple.security.cs.disable-library-validation bool true" \
			"$DMG_ENTITLEMENTS"
	fi
	ENTITLEMENTS="$DMG_ENTITLEMENTS"
fi

# The Xcode build leaves some frameworks without the hardened runtime, so sign
# every framework again before the app.
for framework in "$APP"/Contents/Frameworks/*.framework; do
	sign "$framework"
done

sign --entitlements "$ENTITLEMENTS" "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
