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

  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'mixin',
      packageName: 'mixin_desktop',
      version: '6.3.6',
      buildNumber: '600',
      buildSignature: '',
    ),
  );

  test('a proxy turned on after the check hides the DMG update', () async {
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
