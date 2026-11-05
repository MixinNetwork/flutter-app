import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const appcastUrl =
    'https://github.com/MixinNetwork/flutter-app/releases/latest/download/appcast.xml';

const _sparkleNs = 'http://www.andymatuschak.org/xml-namespaces/sparkle';
const _mixinNs = 'https://mixin.one/xml-namespaces/desktop-update';

/// The appcast package of this copy of the app, or null when the app must not
/// update itself (a snap, a package manager or a store installs the update).
String? linuxUpdatePackage({
  required Map<String, String> environment,
  required String executable,
  required Abi abi,
}) {
  final arch = switch (abi) {
    Abi.linuxX64 => 'x64',
    Abi.linuxArm64 => 'arm64',
    _ => null,
  };
  if (arch == null || environment.containsKey('SNAP')) return null;
  if ((environment['APPIMAGE'] ?? '').isNotEmpty) return 'appimage-$arch';
  if (p.isWithin('/usr/lib', executable)) return 'deb-$arch';
  return 'tar-$arch';
}

class AppUpdateItem {
  AppUpdateItem({
    required this.tag,
    required this.build,
    required this.package,
    required this.url,
    required this.sha256,
    required this.signature,
  });

  final String tag;
  final int build;
  final String package;
  final Uri url;
  final String sha256;
  final String signature;

  String get fileName => url.pathSegments.last;
}

/// The newest item of [appcast] for [package] with a build after
/// [currentBuild], or null.
AppUpdateItem? findAppUpdate(String appcast, String package, int currentBuild) {
  AppUpdateItem? newest;
  for (final item in XmlDocument.parse(appcast).findAllElements('item')) {
    final enclosure = item.getElement('enclosure');
    if (enclosure?.getAttribute('package', namespace: _mixinNs) != package) {
      continue;
    }
    final build = int.tryParse(
      item.getElement('version', namespace: _sparkleNs)?.innerText ?? '',
    );
    final tag = enclosure!.getAttribute('tag', namespace: _mixinNs);
    final url = Uri.tryParse(enclosure.getAttribute('url') ?? '');
    final sha256 = enclosure.getAttribute('sha256', namespace: _mixinNs);
    final signature = enclosure.getAttribute('signature', namespace: _mixinNs);
    if (build == null ||
        build <= currentBuild ||
        tag == null ||
        url == null ||
        url.pathSegments.isEmpty ||
        sha256 == null ||
        signature == null) {
      continue;
    }
    if (newest == null || build > newest.build) {
      newest = AppUpdateItem(
        tag: tag,
        build: build,
        package: package,
        url: url,
        sha256: sha256,
        signature: signature,
      );
    }
  }
  return newest;
}

Future<String> sha256File(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

/// Whether [fileSha256] is the downloaded file of [item], signed by the
/// release key. The signed text has the tag and build, so an older package
/// cannot be listed as a newer one.
bool verifyAppUpdate(
  AppUpdateItem item,
  String fileSha256,
  List<int> publicKey,
) {
  if (fileSha256 != item.sha256 || publicKey.length != ed.PublicKeySize) {
    return false;
  }
  final Uint8List signature;
  try {
    signature = base64Decode(item.signature);
  } on FormatException {
    return false;
  }
  if (signature.length != ed.SignatureSize) return false;
  final text =
      'mixin-desktop-update\n${item.tag}\n${item.build}\n${item.package}\n'
      '${item.fileName}\n$fileSha256';
  return ed.verify(ed.PublicKey(publicKey), utf8.encode(text), signature);
}

/// A new file to download [package] into, alone in a new private directory:
/// next to an AppImage, so the update is a rename; else in the temp
/// directory. Its name does not come from the appcast.
Future<File> createLinuxUpdateFile(
  String package,
  Map<String, String> environment,
) async {
  final parent = package.startsWith('appimage-')
      ? Directory(p.dirname(environment['APPIMAGE']!))
      : Directory.systemTemp;
  // A download that was interrupted (the app was closed or killed) leaves its
  // directory behind. A recent one can belong to an installer that still
  // waits, for example at the pkexec prompt.
  final now = DateTime.now();
  try {
    await for (final entity in parent.list()) {
      if (entity is Directory &&
          p.basename(entity.path).startsWith('.mixin_update_') &&
          now.difference(entity.statSync().modified).inDays >= 1) {
        try {
          await entity.delete(recursive: true);
        } on FileSystemException {
          // Another user's directory in the shared temp directory.
        }
      }
    }
  } on FileSystemException {
    // The parent cannot be listed; createTemp reports a real problem.
  }
  final directory = await parent.createTemp('.mixin_update_');
  final name = package.startsWith('appimage-')
      ? 'update.AppImage'
      : package.startsWith('deb-')
      ? 'update.deb'
      : 'update.tar';
  return File(p.join(directory.path, name));
}

/// Whether this copy can install [package] by itself.
Future<bool> canInstallLinuxUpdate(
  String package,
  Map<String, String> environment,
  String executable,
) async {
  if (package.startsWith('deb-')) {
    return (await Process.run('sh', ['-c', 'command -v pkexec'])).exitCode == 0;
  }
  // The AppImage file or the bundle directory is replaced in its parent.
  final parent = package.startsWith('appimage-')
      ? p.dirname(environment['APPIMAGE']!)
      : p.dirname(p.dirname(executable));
  final probe = File(p.join(parent, '.mixin_update_${pid}_probe'));
  try {
    await probe.writeAsString('');
    await probe.delete();
    return true;
  } on FileSystemException {
    return false;
  }
}

// Waits for the app to exit, installs the package and starts the app again.
// The arguments are: pid, package, file, executable, APPIMAGE.
@visibleForTesting
const linuxInstallScript = r'''
while kill -0 "$1" 2>/dev/null; do sleep 0.2; done
package=$2 file=$3 executable=$4 appimage=$5
dir=$(dirname "$file")
case "$package" in
appimage-*)
  chmod +x "$file" && mv -f "$file" "$appimage"
  rm -rf "$dir"
  exec "$appimage"
  ;;
tar-*)
  bundle=$(dirname "$executable")
  new="$bundle.update" old="$bundle.old"
  rm -rf "$new" "$old"
  # The release tar is not compressed, though its name ends in .tar.gz.
  if mkdir "$new" && tar -xf "$file" -C "$new" && [ -x "$new/$(basename "$executable")" ]; then
    if mv "$bundle" "$old"; then
      if mv "$new" "$bundle"; then rm -rf "$old"; else mv "$old" "$bundle"; fi
    fi
  fi
  rm -rf "$new" "$dir"
  exec "$executable"
  ;;
deb-*)
  pkexec apt-get install -y "$file"
  rm -rf "$dir"
  exec "$executable"
  ;;
esac
''';

/// Starts the installer of [file] for [package]. It waits until this process
/// exits, so call `exit` after it.
Future<void> startLinuxUpdateInstall({
  required String package,
  required File file,
  required String executable,
  required Map<String, String> environment,
}) => Process.start(
  '/bin/sh',
  [
    '-c',
    linuxInstallScript,
    'sh',
    '$pid',
    package,
    file.path,
    executable,
    environment['APPIMAGE'] ?? '',
  ],
  mode: ProcessStartMode.detached,
);
