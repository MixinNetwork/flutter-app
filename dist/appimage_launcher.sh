#!/bin/sh

set -eu

case "$(uname -m)" in
  x86_64)
    gnu_triplet=x86_64-linux-gnu
    ;;
  aarch64|arm64)
    gnu_triplet=aarch64-linux-gnu
    ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mixin"
cache_file="$cache_dir/gtk-3.0-immodules-$gnu_triplet.cache"
cache_tmp="$cache_file.$$"
bundled_cache="$APPDIR/usr/lib/$gnu_triplet/gtk-3.0/3.0.0/immodules.cache"

mkdir -p "$cache_dir"
sed "s|@APPDIR@|$APPDIR|g" "$bundled_cache" > "$cache_tmp"
mv "$cache_tmp" "$cache_file"

export GTK_IM_MODULE_FILE="$cache_file"
exec "$APPDIR/mixin_desktop" "$@"
