#!/bin/bash

app_name="mixin_desktop"
current_dir=$(dirname "$0")

# Get architecture from first argument, default to amd64
arch="${1:-amd64}"

# Map architecture names
if [ "$arch" = "amd64" ] || [ "$arch" = "x64" ]; then
  flutter_arch="x64"
elif [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
  flutter_arch="arm64"
else
  echo "Error: Unsupported architecture: ${arch}"
  exit 1
fi

project_dir="${current_dir}/.."
package_dir="${current_dir}/snap/mixin_desktop"

snap_craft_file="${current_dir}/snap/snap/snapcraft.yaml"

rm -rf "${package_dir}"

# read version from pubspec.yaml
version=$(cat "${project_dir}/pubspec.yaml" | grep "^version:" | awk '{print $2}' | tr -d '"')
version=$(echo "${version}" | sed 's/+.*//')

# check version only contains numbers and dots
if ! [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Invalid version format: ${version}"
  exit 1
fi

echo "Preparing snap for architecture: ${flutter_arch}"

# update snapcraft file version
sed -i "s/version:.*/version: ${version}/g" "${snap_craft_file}"

# copy bundle to snap
cp -fr "$project_dir/build/linux/${flutter_arch}/release/bundle/." "$package_dir"