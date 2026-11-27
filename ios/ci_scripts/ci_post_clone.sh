#!/bin/sh

set -eu

FLUTTER_VERSION="3.50.0"
FLUTTER_ROOT="$HOME/flutter"

cd "$CI_PRIMARY_REPOSITORY_PATH"

if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_ROOT"
fi

export PATH="$HOME/.cargo/bin:$FLUTTER_ROOT/bin:$PATH"

if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
fi

flutter --version
flutter precache --ios
flutter pub get

set -- --config-only --release --no-codesign
if [ -n "${MIXIN_GIPHY_KEY:-}" ]; then
  set -- "$@" --dart-define="MIXIN_GIPHY_KEY=$MIXIN_GIPHY_KEY"
fi
if [ -n "${MIXIN_RECAPTCHA_KEY:-}" ]; then
  set -- "$@" --dart-define="MIXIN_RECAPTCHA_KEY=$MIXIN_RECAPTCHA_KEY"
fi
if [ -n "${MIXIN_HCAPTCHA_KEY:-}" ]; then
  set -- "$@" --dart-define="MIXIN_HCAPTCHA_KEY=$MIXIN_HCAPTCHA_KEY"
fi
flutter build ios "$@"

cd ios
pod install --repo-update
