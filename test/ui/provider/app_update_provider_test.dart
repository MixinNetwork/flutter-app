import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_app/ui/provider/app_update_provider.dart';
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

void main() {
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
