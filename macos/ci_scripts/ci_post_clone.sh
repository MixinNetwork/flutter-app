#!/bin/sh

set -eu

FLUTTER_VERSION="3.50.0"
FLUTTER_ROOT="$HOME/flutter"

cd "$CI_PRIMARY_REPOSITORY_PATH"

if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version
flutter precache --macos
flutter pub get

if [ -n "${MIXIN_GIPHY_KEY:-}" ]; then
  flutter build macos --config-only --release --dart-define="MIXIN_GIPHY_KEY=$MIXIN_GIPHY_KEY"
else
  flutter build macos --config-only --release
fi

cd macos
pod install --repo-update
