import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_app/utils/app_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String _appcast(List<String> items) =>
    '''
<?xml version='1.0' encoding='utf-8'?>
<rss xmlns:mixin="https://mixin.one/xml-namespaces/desktop-update" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>${items.join()}</channel>
</rss>''';

String _item(
  String package,
  int build, {
  String tag = 'v6.3.7',
  String name = 'mixin_desktop_linux_amd64.AppImage',
  String sha256 = 'aa',
  String signature = 'c2ln',
}) =>
    '''
<item>
  <sparkle:version>$build</sparkle:version>
  <enclosure url="https://example.com/$tag/$name" length="1" sparkle:os="linux"
    mixin:package="$package" mixin:tag="$tag" mixin:sha256="$sha256" mixin:signature="$signature" />
</item>''';

void main() {
  group('linuxUpdatePackage', () {
    String? package(
      Map<String, String> env,
      String exe, [
      Abi abi = Abi.linuxX64,
    ]) => linuxUpdatePackage(environment: env, executable: exe, abi: abi);

    test('detects how the app was installed', () {
      expect(
        package({'APPIMAGE': '/home/a/Mixin.AppImage'}, '/tmp/.mount/x'),
        'appimage-x64',
      );
      expect(package({}, '/usr/lib/mixin_desktop/mixin_desktop'), 'deb-x64');
      expect(
        package({}, '/home/a/mixin/mixin_desktop', Abi.linuxArm64),
        'tar-arm64',
      );
    });

    test('does not update a snap or an unknown architecture', () {
      expect(package({'SNAP': '/snap/mixin'}, '/snap/mixin/1/mixin'), isNull);
      expect(package({}, '/opt/mixin/mixin', Abi.linuxRiscv64), isNull);
    });
  });

  group('findAppUpdate', () {
    test('takes the newest build of this package after the current build', () {
      final appcast = _appcast([
        _item('appimage-x64', 602),
        _item('appimage-x64', 605, tag: 'v6.4.0'),
        _item('deb-x64', 700, name: 'mixin_desktop_linux_amd64.deb'),
        _item('appimage-x64', 601),
      ]);
      final item = findAppUpdate(appcast, 'appimage-x64', 601)!;
      expect(item.build, 605);
      expect(item.tag, 'v6.4.0');
      expect(item.fileName, 'mixin_desktop_linux_amd64.AppImage');
      expect(item.sha256, 'aa');
      expect(item.signature, 'c2ln');
    });

    test('has no update when nothing is newer or the package is missing', () {
      final appcast = _appcast([_item('appimage-x64', 601)]);
      expect(findAppUpdate(appcast, 'appimage-x64', 601), isNull);
      expect(findAppUpdate(appcast, 'tar-x64', 1), isNull);
    });
  });

  group('verifyAppUpdate', () {
    final key = ed.generateKey();
    const name = 'mixin_desktop_linux_amd64.AppImage';
    final fileSha = sha256.convert([1, 2, 3]).toString();

    String sign(
      String tag,
      int build,
      String package,
      String fileName,
    ) => base64Encode(
      ed.sign(
        key.privateKey,
        utf8.encode(
          'mixin-desktop-update\n$tag\n$build\n$package\n$fileName\n$fileSha',
        ),
      ),
    );

    AppUpdateItem item({
      String tag = 'v6.3.7',
      int build = 602,
      String package = 'appimage-x64',
      String fileName = name,
      String? sha,
      String? signature,
    }) => AppUpdateItem(
      tag: tag,
      build: build,
      package: package,
      url: Uri.parse('https://example.com/$tag/$fileName'),
      sha256: sha ?? fileSha,
      signature: signature ?? sign('v6.3.7', 602, 'appimage-x64', name),
    );

    test('accepts the signed package', () {
      expect(verifyAppUpdate(item(), fileSha, key.publicKey.bytes), isTrue);
    });

    test('rejects a changed tag, build, package, file name or file', () {
      for (final changed in [
        item(tag: 'v9.9.9'),
        item(build: 9999),
        item(package: 'tar-x64'),
        item(fileName: 'other.AppImage'),
      ]) {
        expect(verifyAppUpdate(changed, fileSha, key.publicKey.bytes), isFalse);
      }
      final otherSha = sha256.convert([4]).toString();
      expect(verifyAppUpdate(item(), otherSha, key.publicKey.bytes), isFalse);
      expect(
        verifyAppUpdate(item(sha: otherSha), otherSha, key.publicKey.bytes),
        isFalse,
      );
    });

    test('rejects another key and a broken signature', () {
      expect(
        verifyAppUpdate(item(), fileSha, ed.generateKey().publicKey.bytes),
        isFalse,
      );
      expect(
        verifyAppUpdate(
          item(signature: 'not base64!'),
          fileSha,
          key.publicKey.bytes,
        ),
        isFalse,
      );
      expect(verifyAppUpdate(item(), fileSha, Uint8List(3)), isFalse);
    });
  });

  test('sha256File hashes the whole file', () async {
    final dir = Directory.systemTemp.createTempSync();
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'f'))
      ..writeAsBytesSync(List.filled(70000, 7));
    expect(
      await sha256File(file),
      sha256.convert(List.filled(70000, 7)).toString(),
    );
  });

  group('linuxInstallScript', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync());
    tearDown(() => dir.deleteSync(recursive: true));

    // A finished process, so the script does not wait.
    Future<String> deadPid() async =>
        '${(await Process.start('true', [])).pid}';

    File program(String path, String marker) => File(path)
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '#!/bin/sh\necho "$marker" > "${dir.path}/started"\n',
      );

    Future<void> run(List<String> args) async {
      final result = await Process.run('/bin/sh', [
        '-c',
        linuxInstallScript,
        'sh',
        ...args,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    }

    test('replaces the AppImage and starts the new one', () async {
      final appimage = program(p.join(dir.path, 'Mixin.AppImage'), 'old');
      final update = program(p.join(dir.path, 'download', 'u'), 'new');
      await run([
        await deadPid(),
        'appimage-x64',
        update.path,
        '/tmp/.mount/mixin',
        appimage.path,
      ]);
      expect(
        File(p.join(dir.path, 'started')).readAsStringSync().trim(),
        'new',
      );
      expect(Directory(p.join(dir.path, 'download')).existsSync(), isFalse);
    });

    test('replaces the tar bundle and starts it', () async {
      final bundle = p.join(dir.path, 'mixin');
      final executable = p.join(bundle, 'mixin_desktop');
      program(executable, 'old');
      Process.runSync('chmod', ['+x', executable]);
      final newBundle = p.join(dir.path, 'new');
      program(p.join(newBundle, 'mixin_desktop'), 'new');
      Process.runSync('chmod', ['+x', p.join(newBundle, 'mixin_desktop')]);
      final archive = p.join(dir.path, 'download', 'update.tar');
      Directory(p.dirname(archive)).createSync();
      // As .github/workflows/manual-build.yml builds it: not compressed.
      Process.runSync('tar', ['-cf', archive, '-C', newBundle, '.']);

      await run([await deadPid(), 'tar-x64', archive, executable, '']);
      expect(
        File(p.join(dir.path, 'started')).readAsStringSync().trim(),
        'new',
      );
      expect(Directory('$bundle.old').existsSync(), isFalse);
      expect(Directory(p.dirname(archive)).existsSync(), isFalse);
    });

    test('keeps the old tar bundle when the archive is broken', () async {
      final bundle = p.join(dir.path, 'mixin');
      final executable = p.join(bundle, 'mixin_desktop');
      program(executable, 'old');
      Process.runSync('chmod', ['+x', executable]);
      final archive = File(p.join(dir.path, 'download', 'update.tar'))
        ..createSync(recursive: true)
        ..writeAsStringSync('broken');

      await run([await deadPid(), 'tar-x64', archive.path, executable, '']);
      expect(
        File(p.join(dir.path, 'started')).readAsStringSync().trim(),
        'old',
      );
      expect(Directory('$bundle.update').existsSync(), isFalse);
      expect(archive.parent.existsSync(), isFalse);
    });
  });

  group('createLinuxUpdateFile', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync());
    tearDown(() => dir.deleteSync(recursive: true));

    test('puts each download alone in a new private directory', () async {
      final environment = {'APPIMAGE': p.join(dir.path, 'Mixin.AppImage')};
      final first = await createLinuxUpdateFile('appimage-x64', environment);
      final second = await createLinuxUpdateFile('appimage-x64', environment);

      expect(first.parent.parent.path, dir.path);
      expect(first.parent.path, isNot(second.parent.path));
      expect(p.basename(first.path), 'update.AppImage');
      expect(first.parent.statSync().modeString(), 'rwx------');
    });

    test('names the file by the package, not by the appcast', () async {
      for (final (package, name) in [
        ('deb-x64', 'update.deb'),
        ('tar-arm64', 'update.tar'),
      ]) {
        final file = await createLinuxUpdateFile(package, const {});
        addTearDown(() => file.parent.deleteSync(recursive: true));
        expect(p.basename(file.path), name);
        expect(file.parent.parent.path, Directory.systemTemp.path);
      }
    });
  });
}
