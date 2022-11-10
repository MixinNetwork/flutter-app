#!/bin/bash

current_dir=$(dirname "$0")
project_dir="${current_dir}/.."


rm "$project_dir/dist/flatpak/mixin-linux-portable.tar.gz"
tar -C "${project_dir}/build/linux/x64/release/bundle" -cvf mixin-linux-portable.tar.gz .

pushd "$project_dir/dist/flatpak" || exit
flatpak-builder --force-clean build-dir one.mixin.messenger.desktop.yaml
popd || exit