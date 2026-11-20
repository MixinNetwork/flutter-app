#!/bin/sh

# Notarize a signed .app or .dmg and staple the ticket to it.
#
# usage: macos_notarize.sh <app_or_dmg>
#
# Reads the App Store Connect API key from APP_STORE_CONNECT_API_KEY_PATH,
# APP_STORE_CONNECT_API_KEY_ID and APP_STORE_CONNECT_ISSUER_ID.

set -eu

if [ $# -ne 1 ]; then
	echo "usage: $0 <app_or_dmg>" >&2
	exit 1
fi

TARGET="$1"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

case "$TARGET" in
*.app)
	SUBMISSION="$WORK_DIR/$(basename "$TARGET").zip"
	ditto -c -k --keepParent "$TARGET" "$SUBMISSION"
	;;
*)
	SUBMISSION="$TARGET"
	;;
esac

xcrun notarytool submit "$SUBMISSION" \
	--key "$APP_STORE_CONNECT_API_KEY_PATH" \
	--key-id "$APP_STORE_CONNECT_API_KEY_ID" \
	--issuer "$APP_STORE_CONNECT_ISSUER_ID" \
	--wait --output-format json >"$WORK_DIR/result.json"

cat "$WORK_DIR/result.json"
echo

ID="$(plutil -extract id raw "$WORK_DIR/result.json")"
STATUS="$(plutil -extract status raw "$WORK_DIR/result.json")"

if [ "$STATUS" != "Accepted" ]; then
	echo "error: notarization $ID finished with status $STATUS" >&2
	xcrun notarytool log "$ID" \
		--key "$APP_STORE_CONNECT_API_KEY_PATH" \
		--key-id "$APP_STORE_CONNECT_API_KEY_ID" \
		--issuer "$APP_STORE_CONNECT_ISSUER_ID" >&2 || true
	exit 1
fi

xcrun stapler staple "$TARGET"
xcrun stapler validate "$TARGET"
