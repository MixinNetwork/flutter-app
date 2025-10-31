#!/bin/bash

app_name="mixin_desktop"
current_dir=$(dirname "$0")

# Get architecture from first argument, default to amd64
arch="${1:-amd64}"

# Map Flutter arch to deb arch
if [ "$arch" = "amd64" ] || [ "$arch" = "x64" ]; then
  deb_arch="amd64"
  flutter_arch="x64"
elif [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
  deb_arch="arm64"
  flutter_arch="arm64"
else
  echo "Error: Unsupported architecture: ${arch}"
  exit 1
fi

project_dir="${current_dir}/.."
package_dir="${project_dir}/build/deb_package_${deb_arch}"

rm -rf "${package_dir}"

control_file="${current_dir}/deb/DEBIAN/control"

# read version from pubspec.yaml
version=$(cat "${project_dir}/pubspec.yaml" | grep "^version:" | awk '{print $2}' | tr -d '"')
version=$(echo "${version}" | sed 's/+.*//')

# check version only contains numbers and dots
if ! [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Invalid version format: ${version}"
  exit 1
fi

echo "Building deb package for architecture: ${deb_arch}"
echo "update control file with version: ${version}"

cp -fr "$current_dir/deb/." "$package_dir"

# update control file version and architecture
sed -i "s/Version:.*/Version: ${version}/g" "${package_dir}/DEBIAN/control"
sed -i "s/Architecture:.*/Architecture: ${deb_arch}/g" "${package_dir}/DEBIAN/control"

mkdir -p "$package_dir/usr/lib/$app_name"
cp -fr "$project_dir/build/linux/${flutter_arch}/release/bundle/." \
  "$package_dir/usr/lib/$app_name"

mkdir -p "$package_dir/usr/bin"
pushd "$package_dir/usr/bin" || exit
ln -s "../lib/$app_name/$app_name" "$app_name"
popd || exit

dpkg-deb --build --root-owner-group "$package_dir" "$project_dir/build/${app_name}_${deb_arch}.deb"