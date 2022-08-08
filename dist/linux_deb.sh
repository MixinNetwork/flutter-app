#!/bin/bash

app_name="mixin_desktop"
current_dir=$(dirname "$0")

project_dir="${current_dir}/.."
package_dir="${project_dir}/build/deb_package"

rm -rf "${package_dir}"

cp -fr "$current_dir/deb/." "$package_dir"
mkdir -p "$package_dir/usr/lib/$app_name"
cp -fr "$project_dir/build/linux/x64/release/bundle/." \
  "$package_dir/usr/lib/$app_name"

mkdir -p "$package_dir/usr/bin"
pushd "$package_dir/usr/bin" || exit
ln -s "../lib/$app_name/$app_name" "$app_name"
popd || exit

dpkg-deb --build --root-owner-group "$package_dir" "$project_dir/build/${app_name}_amd64.deb"