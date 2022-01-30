import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../logger.dart';

const kMixinVersion = '0.19.1';

final _packageInfo = PackageInfo(
  appName: 'mixin',
  packageName: 'mixin_desktop',
  version: kMixinVersion,
  buildNumber: '',
);

Future<PackageInfo> getPackageInfo() async {
  if (Platform.isWindows) {
    return _packageInfo;
  }
  try {
    return await PackageInfo.fromPlatform();
  } catch (error, stack) {
    e('get package info failed. $error $stack');
  }
  assert(false, 'get package info failed');
  // fallback if we can not get packageInfo dynamic.
  return _packageInfo;
}
