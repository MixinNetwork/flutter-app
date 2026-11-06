import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/ui/provider/app_update_provider.dart';
import 'package:flutter_app/utils/app_update.dart';
import 'package:flutter_app/utils/proxy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Server implements HttpClientAdapter {
  String appcast = '';
  final requests = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    return options.uri.path.endsWith('.xml')
        ? ResponseBody.fromString(appcast, 200)
        : ResponseBody.fromBytes([1, 2, 3], 200);
  }

  @override
  void close({bool force = false}) {}
}

String _appcast(String items) =>
    '''
<?xml version='1.0' encoding='utf-8'?>
<rss xmlns:mixin="https://mixin.one/xml-namespaces/desktop-update" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>$items</channel>
</rss>''';

const _tar = '''
<item>
  <sparkle:version>601</sparkle:version>
  <enclosure url="https://example.com/v6.3.7/mixin.tar.gz" length="3" sparkle:os="linux"
    mixin:package="tar-x64" mixin:tag="v6.3.7" mixin:sha256="aa" mixin:signature="c2ln" />
</item>''';

const _dmg = '''
<item>
  <sparkle:version>601</sparkle:version>
  <enclosure url="https://example.com/v6.3.7/mixin.dmg" length="3" sparkle:os="macos"
    mixin:package="dmg" sparkle:edSignature="c2ln" />
</item>''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> calls;
  late int? count;
  late PlatformException? countError;
  late Completer<void> install;
  late PlatformException? installError;

  setUp(() {
    calls = [];
    count = 1;
    countError = null;
    install = Completer()..complete();
    installError = null;
    messenger.setMockMethodCallHandler(storeUpdateChannel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'storeUpdateCount':
          if (countError != null) throw countError!;
          return count;
        case 'installStoreUpdates':
          await install.future;
          if (installError != null) throw installError!;
          return null;
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(storeUpdateChannel, null));

  Future<(ProviderContainer, AppUpdateNotifier)> start() async {
    final provider = StateNotifierProvider<AppUpdateNotifier, AppUpdateState>(
      (ref) => AppUpdateNotifier(ref, windows: true),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(provider.notifier);
    await pumpEventQueue();
    return (container, notifier);
  }

  Future<void> sendProgress(double progress) => messenger.handlePlatformMessage(
    storeUpdateChannel.name,
    storeUpdateChannel.codec.encodeMethodCall(MethodCall('progress', progress)),
    (_) {},
  );

  test('not packaged: shows nothing and installs nothing', () async {
    count = null;
    final (_, notifier) = await start();
    expect(notifier.state.status, AppUpdateStatus.none);
    await notifier.update();
    expect(calls, ['storeUpdateCount']);
  });

  test('no updates: shows nothing', () async {
    count = 0;
    final (_, notifier) = await start();
    expect(notifier.state.status, AppUpdateStatus.none);
  });

  test('store error on check: shows nothing', () async {
    countError = PlatformException(code: 'store_error');
    final (_, notifier) = await start();
    expect(notifier.state.status, AppUpdateStatus.none);
  });

  test('available, install with progress, done', () async {
    install = Completer();
    final (_, notifier) = await start();
    expect(notifier.state.status, AppUpdateStatus.available);

    final done = notifier.update();
    await pumpEventQueue();
    expect(notifier.state.status, AppUpdateStatus.downloading);
    expect(notifier.state.progress, 0);

    await sendProgress(0.4);
    expect(notifier.state.status, AppUpdateStatus.downloading);
    expect(notifier.state.progress, 0.4);

    // A second click while it runs does nothing.
    await notifier.update();
    expect(calls, ['storeUpdateCount', 'installStoreUpdates']);

    install.complete();
    await done;
    expect(notifier.state.status, AppUpdateStatus.none);
  });

  test('install canceled or failed: retry', () async {
    final (_, notifier) = await start();
    installError = PlatformException(code: 'store_state', message: '4');
    await notifier.update();
    expect(notifier.state.status, AppUpdateStatus.failed);

    // Late progress does not hide the retry.
    await sendProgress(0.9);
    expect(notifier.state.status, AppUpdateStatus.failed);

    installError = null;
    await notifier.update();
    expect(notifier.state.status, AppUpdateStatus.none);
    expect(calls, [
      'storeUpdateCount',
      'installStoreUpdates',
      'installStoreUpdates',
    ]);
  });

  test('a proxy turned on after the check hides the DMG update', () async {
    PackageInfo.setMockInitialValues(
      appName: 'mixin',
      packageName: 'mixin_desktop',
      version: '6.3.6',
      buildNumber: '600',
      buildSignature: '',
    );
    final installs = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('mixin_desktop/app_update'),
          (call) async => installs.add(call),
        );
    final server = _Server()..appcast = _appcast(_dmg);
    ProxyConfig? proxy;
    final provider = StateNotifierProvider<AppUpdateNotifier, AppUpdateState>(
      (ref) => AppUpdateNotifier.test(
        ref,
        package: 'dmg',
        publicKey: List.filled(32, 0),
        dio: () => Dio()..httpClientAdapter = server,
        mac: MacUpdateChannel.dmg,
        proxy: () => proxy,
      ),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(provider.notifier);

    await notifier.check();
    expect(container.read(provider).status, AppUpdateStatus.available);

    proxy = ProxyConfig(
      type: ProxyType.http,
      host: '127.0.0.1',
      port: 8080,
      id: 'proxy',
    );
    await notifier.update();
    expect(installs, isEmpty);
    expect(container.read(provider).status, AppUpdateStatus.none);
  });

  test('a later appcast without the package keeps the update', () async {
    PackageInfo.setMockInitialValues(
      appName: 'mixin',
      packageName: 'mixin_desktop',
      version: '6.3.6',
      buildNumber: '600',
      buildSignature: '',
    );
    final server = _Server();
    final provider = StateNotifierProvider<AppUpdateNotifier, AppUpdateState>(
      (ref) => AppUpdateNotifier.test(
        ref,
        package: 'tar-x64',
        publicKey: List.filled(32, 0),
        dio: () => Dio()..httpClientAdapter = server,
      ),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(provider.notifier);

    server.appcast = _appcast(_tar);
    await notifier.check();
    expect(container.read(provider).status, AppUpdateStatus.available);

    // For example, the Linux job of the next release failed.
    server.appcast = _appcast('');
    await notifier.check();
    expect(container.read(provider).status, AppUpdateStatus.available);

    // The tap still downloads the kept item; its test signature fails.
    await notifier.update();
    expect(
      server.requests.last,
      Uri.parse('https://example.com/v6.3.7/mixin.tar.gz'),
    );
    expect(container.read(provider).status, AppUpdateStatus.failed);
  });
}
