#!/bin/sh
# End-to-end test of the DMG update: 6.3.6 (601) finds 6.3.7 (602) in a local
# appcast, Sparkle downloads and installs it, and 6.3.7 runs in its place.
# The builds are ad-hoc signed with a throwaway update key.
#
# Usage, from the repository root: dist/test_update_macos.sh
# It overwrites assets/update_ed25519.pub, the bundle id in
# macos/Runner/Configs/AppInfo.xcconfig (a test id, so it does not touch the
# data of an installed Mixin) and build/. OPENSSL must be OpenSSL 3 (the
# system LibreSSL cannot make Ed25519 keys).

set -eu

OPENSSL="${OPENSSL:-openssl}"
PORT=8766
# The real path: the process of the app has it, not the /var symlink.
WORK="$(cd -P "$(mktemp -d)" && pwd)"
APP="$WORK/Applications/Mixin.app"
SERVER=
cleanup() {
	[ -n "$SERVER" ] && kill "$SERVER" 2>/dev/null
	pkill -f "$APP/Contents/MacOS/" 2>/dev/null || true
	if [ -n "${KEEP_WORK:-}" ]; then echo "kept $WORK"; else rm -rf "$WORK"; fi
}
trap cleanup EXIT

sed -i '' 's/^PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = one.mixin.messenger.desktop.updatetest/' \
	macos/Runner/Configs/AppInfo.xcconfig

"$OPENSSL" genpkey -algorithm ed25519 -out "$WORK/key.pem"
"$OPENSSL" pkey -in "$WORK/key.pem" -pubout -outform DER | tail -c 32 |
	base64 >assets/update_ed25519.pub

# Ad-hoc code has no Team ID, so library validation of the hardened runtime
# refuses every embedded framework. A Developer ID build does not need this.
ENTITLEMENTS="$WORK/test.entitlements"
cp macos/Runner/Release.entitlements "$ENTITLEMENTS"
/usr/libexec/PlistBuddy \
	-c "Add :com.apple.security.cs.disable-library-validation bool true" \
	"$ENTITLEMENTS"

# build <entry point> <version> <build number> <app>
build() {
	flutter build macos -t "$1" --build-name "$2" --build-number "$3"
	mkdir -p "$(dirname "$4")"
	ditto build/macos/Build/Products/Release/Mixin.app "$4"
	dist/macos_sparkle.sh "$4"
	dist/macos_sign.sh "$4" - "$ENTITLEMENTS"
}

build integration_test/app_update_e2e.dart 6.3.7 602 "$WORK/new/Mixin.app"
mkdir -p "$WORK/served/v6.3.7"
hdiutil create -quiet -volname Mixin -srcfolder "$WORK/new/Mixin.app" \
	-format UDZO "$WORK/served/v6.3.7/mixin-6.3.7.dmg"
python3 dist/update_appcast.py --openssl "$OPENSSL" --tag v6.3.7 --build 602 \
	--key "$WORK/key.pem" --public-key assets/update_ed25519.pub \
	--url-prefix "http://127.0.0.1:$PORT/v6.3.7" --out "$WORK/served/appcast.xml" \
	dmg="$WORK/served/v6.3.7/mixin-6.3.7.dmg"

build integration_test/app_update_e2e.dart 6.3.6 601 "$APP"

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$WORK/served" \
	>"$WORK/server.log" 2>&1 &
SERVER=$!
# The old app taps its update item as soon as it shows.
open -n "$APP" --env "MIXIN_UPDATE_APPCAST_URL=http://127.0.0.1:$PORT/appcast.xml" \
	--env MIXIN_UPDATE_E2E_TAP=1 \
	--stdout "$WORK/app.log" --stderr "$WORK/app.log"

for i in $(seq 1 60); do
	sleep 5
	build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
		"$APP/Contents/Info.plist" 2>/dev/null || true)"
	running="$(pgrep -f "$APP/Contents/MacOS/" || true)"
	echo "$i build=$build_number running=${running:+yes}"
	if [ "$build_number" = 602 ] && [ -n "$running" ]; then
		codesign --verify --deep --strict "$APP"
		echo "6.3.6 (601) updated itself to 6.3.7 (602), which runs"
		exit 0
	fi
done
tail -n 40 "$WORK/server.log" "$WORK/app.log"
echo "6.3.7 is not installed and running" >&2
exit 1
