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

# The Xcode build leaves some frameworks without the hardened runtime, so sign
# every framework again before the app.
for framework in "$APP"/Contents/Frameworks/*.framework; do
	codesign --force --sign "$IDENTITY" --options runtime "$TIMESTAMP" "$framework"
done

codesign --force --sign "$IDENTITY" --options runtime "$TIMESTAMP" \
	--entitlements "$ENTITLEMENTS" "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
