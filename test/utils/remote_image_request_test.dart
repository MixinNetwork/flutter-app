import 'dart:io';

import 'package:flutter_app/utils/proxy.dart';
import 'package:flutter_app/utils/remote_image_request.dart';
import 'package:flutter_app/widgets/global_image_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/testing.dart';
// The resolver type is not exported.
import 'package:rhttp/src/model/settings.dart' show DynamicDnsSettings;

void main() {
  http.Client client() {
    final client = IOClient();
    addTearDown(client.close);
    return client;
  }

  test('only public http and https addresses are allowed', () {
    for (final url in [
      'https://mixin-images.zeromesh.net/a.png',
      'http://example.com./a.png',
      'https://xn--fiqs8s.example/a.png',
      'http://8.8.8.8/a.png',
      // Fake-IP proxies answer DNS with this range.
      'http://198.18.0.5/a.png',
      'http://[2606:4700:4700::1111]/a.png',
      'http://[64:ff9b::808:808]/a.png',
      // Next to the ranges that are not allowed.
      'http://192.0.3.1/a.png',
      'http://198.51.101.1/a.png',
      'http://203.0.114.1/a.png',
      'http://[2001:db9::1]/a.png',
      'http://[2001:2:1::1]/a.png',
      // Names in other scripts.
      'https://bücher.example/a.png',
      'https://BÜCHER.example/a.png',
      'https://пример.example/a.png',
      'https://例え.テスト/a.png',
      'https://한글.example/a.png',
    ]) {
      expect(isPublicImageUri(Uri.parse(url)), isTrue, reason: url);
    }
    for (final url in [
      'file:///etc/hosts',
      'ftp://example.com/a.png',
      'http:///a.png',
      'http://localhost:8080/a.png',
      'http://LOCALHOST./a.png',
      'http://a.localhost/a.png',
      // mDNS names are devices on the local network, also this one.
      'http://nas.local/a.png',
      'http://NAS.Local./a.png',
      'http://127.0.0.1/a.png',
      'http://127.0.0.1./a.png',
      'http://127.1/a.png',
      'http://2130706433/a.png',
      'http://0x7f000001/a.png',
      'http://0x7f.0.0.1/a.png',
      'http://0177.0.0.1/a.png',
      'http://%EF%BC%91%EF%BC%92%EF%BC%97.0.0.1/a.png',
      'http://１２７.0.0.1/a.png',
      'http://127。0。0。1/a.png',
      // These map to "localhost", to ".local" or to an IP address.
      'http://ｌｏｃａｌｈｏｓｔ/a.png',
      'http://local%C2%ADhost/a.png',
      'http://%C5%BF.local/a.png',
      'http://nas.ｌｏｃａｌ/a.png',
      'http://bücher.localhost/a.png',
      'http://bücher.local/a.png',
      'http://bücher。local/a.png',
      'http://①②⑦.0.0.1/a.png',
      'http://%FF.example/a.png',
      'http://0.0.0.0/a.png',
      'http://10.0.0.1/a.png',
      'http://100.64.0.1/a.png',
      'http://169.254.169.254/latest/meta-data',
      'http://172.16.0.1/a.png',
      'http://172.31.255.255/a.png',
      'http://192.0.0.1/a.png',
      'http://192.168.1.1/a.png',
      'http://224.0.0.1/a.png',
      // Documentation and benchmarking ranges are not on the internet.
      'http://192.0.2.1/a.png',
      'http://198.51.100.1/a.png',
      'http://203.0.113.1/a.png',
      'http://[2001:db8::1]/a.png',
      'http://[2001:2::1]/a.png',
      'http://255.255.255.255/a.png',
      'http://[::1]/a.png',
      'http://[::]/a.png',
      'http://[fe80::1]/a.png',
      'http://[fe80::1%25en0]/a.png',
      'http://[fd00::1]/a.png',
      'http://[ff02::1]/a.png',
      'http://[::ffff:127.0.0.1]/a.png',
      'http://[::ffff:7f00:1]/a.png',
      'http://[64:ff9b::7f00:1]/a.png',
      'http://[2002:7f00:1::]/a.png',
      'http://user@127.0.0.1/a.png',
    ]) {
      expect(isPublicImageUri(Uri.parse(url)), isFalse, reason: url);
    }
  });

  test('a name resolves to its public addresses only', () async {
    Future<List<InternetAddress>> lookup(String host) async => [
      InternetAddress('127.0.0.1'),
      InternetAddress('93.184.216.34'),
      InternetAddress('fd00::1'),
    ];

    expect(
      await resolveImageHost('images.example', lookup: lookup),
      ['93.184.216.34'],
    );
    // A system proxy is often configured as localhost.
    expect(await resolveImageHost('localhost', lookup: lookup), hasLength(3));
    expect(
      await resolveImageHost(
        'missing.example',
        lookup: (_) async => throw const SocketException('no such host'),
      ),
      isEmpty,
    );
  });

  test('an image URL cannot name an environment proxy', () {
    final environment = imageEnvironment;
    imageEnvironment = {'HTTPS_PROXY': 'http://Proxy.lan:7890'};
    addTearDown(() => imageEnvironment = environment);

    expect(isPublicImageUri(Uri.parse('http://proxy.lan:8080/a')), isFalse);
    expect(isPublicImageUri(Uri.parse('http://proxy.lan./a')), isFalse);
    expect(isPublicImageUri(Uri.parse('http://other.lan/a')), isTrue);

    imageEnvironment = {'HTTP_PROXY': 'http://proxy.lan.:7890'};
    expect(isPublicImageUri(Uri.parse('http://proxy.lan/a')), isFalse);
    expect(isPublicImageUri(Uri.parse('http://proxy.lan./a')), isFalse);
  });

  test('the resolver lets an environment proxy through', () async {
    final environment = imageEnvironment;
    imageEnvironment = {'HTTP_PROXY': 'http://proxy.lan.:7890'};
    addTearDown(() => imageEnvironment = environment);

    // The native client asks for the name as the environment spells it.
    for (final host in ['proxy.lan.', 'proxy.lan']) {
      expect(
        await resolveImageHost(
          host,
          lookup: (_) async => [InternetAddress('192.168.1.2')],
        ),
        ['192.168.1.2'],
        reason: host,
      );
    }
  });

  for (final (url, proxyHost) in [
    ('http://proxy.lan:8080/a.png', 'Proxy.lan'),
    ('http://proxy.lan.:8080/a.png', 'proxy.lan'),
    ('http://proxy.lan:8080/a.png', 'proxy.lan.'),
  ]) {
    test('the image URL $url cannot name the app proxy $proxyHost', () async {
      await expectLater(
        sendImageRequest(
          Uri.parse(url),
          proxyConfig: ProxyConfig(
            type: ProxyType.http,
            host: proxyHost,
            port: 1080,
            id: 'proxy',
          ),
          client: client(),
        ),
        throwsBlocked,
      );
    });
  }

  test('a SOCKS5 proxy gets only filtered addresses', () async {
    final lookup = imageHostLookup;
    imageHostLookup = (_) async => [InternetAddress('192.168.1.2')];
    addTearDown(() => imageHostLookup = lookup);
    ProxyConfig proxy(ProxyType type) =>
        ProxyConfig(type: type, host: 'Proxy.lan', port: 1080, id: 'proxy');

    // SOCKS5 gets an address, so the app resolves the name.
    final resolve =
        (imageClientSettings(proxy(ProxyType.socks5)).dnsSettings!
                as DynamicDnsSettings)
            .resolver;
    // No address would make the proxy resolve the name itself.
    expect(await resolve('images.example'), ['255.255.255.255']);
    expect(await resolve('proxy.lan'), ['192.168.1.2']);

    // An HTTP proxy gets the name.
    expect(imageClientSettings(proxy(ProxyType.http)).dnsSettings, isNull);
    // The environment can name a SOCKS5 proxy too.
    final direct =
        (imageClientSettings(null).dnsSettings! as DynamicDnsSettings).resolver;
    expect(await direct('images.example'), ['255.255.255.255']);
  });

  test('a local-use NAT64 address counts as its IPv4 address', () async {
    expect(
      await resolveImageHost(
        'images.example',
        lookup: (_) async => [
          InternetAddress('64:ff9b:1::808:808'),
          InternetAddress('64:ff9b:1::a00:1'),
          InternetAddress('64:ff9b:1:1::808:808'),
        ],
      ),
      [InternetAddress('64:ff9b:1::808:808').address],
    );
  });

  test('the image cache does not request a local address', () async {
    final server = await _Server.bind();
    final directory = await Directory.systemTemp.createTemp('image_cache');
    addTearDown(() => directory.delete(recursive: true));
    final cache = GlobalImageCache.forTesting(
      directory: directory,
      maxSizeBytes: 1024,
    );

    await expectLater(
      cache.getBytes(server.url('/a.png'), limitBytes: true).last,
      throwsBlocked,
    );
    expect(server.paths, isEmpty);
  });

  test('every redirect target is checked', () async {
    final local = await _Server.bind();
    final public = await _Server.bind(redirectTo: local.url('/secret'));

    await expectLater(
      sendImageRequest(
        Uri.parse(public.url('/a.png')),
        isAllowed: (uri) => uri.port == public.port,
        client: client(),
      ),
      throwsBlocked,
    );
    expect(public.paths, ['/a.png']);
    expect(local.paths, isEmpty);
  });

  test('allowed redirects are followed', () async {
    final target = await _Server.bind();
    final first = await _Server.bind(redirectTo: target.url('/b.png'));

    final response = await sendImageRequest(
      Uri.parse(first.url('/a.png')),
      isAllowed: (_) => true,
      client: client(),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(await response.stream.toBytes(), [1, 2, 3]);
    expect(target.paths, ['/b.png']);
  });

  test('a redirect sends the previous URL as the referer', () async {
    final target = await _Server.bind();
    final first = await _Server.bind(redirectTo: target.url('/b.png'));

    final response = await sendImageRequest(
      Uri.parse(
        'http://user:password@127.0.0.1:${first.port}/a.png?size=1#part',
      ),
      isAllowed: (_) => true,
      client: client(),
    );
    await response.stream.drain<void>();

    expect(first.referers, [null]);
    expect(target.referers, ['${first.url('/a.png')}?size=1']);
  });

  test('the referer never goes from https to http', () async {
    final referers = <String?>[];
    final client = MockClient((request) async {
      referers.add(request.headers[HttpHeaders.refererHeader]);
      return switch (referers.length) {
        1 => http.Response(
          '',
          302,
          headers: {'location': 'https://cdn.example/b'},
        ),
        2 => http.Response(
          '',
          302,
          headers: {'location': 'http://cdn.example/c'},
        ),
        _ => http.Response('ok', 200),
      };
    });

    await sendImageRequest(
      Uri.parse('https://images.example/a'),
      client: client,
    );

    expect(referers, [null, 'https://images.example/a', null]);
  });

  test('a redirect loop ends', () async {
    final server = await _Server.bind(redirectTo: '/again');

    await expectLater(
      sendImageRequest(
        Uri.parse(server.url('/a.png')),
        isAllowed: (_) => true,
        client: client(),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('too many redirects'),
        ),
      ),
    );
    expect(server.paths, hasLength(11));
  });
}

final throwsBlocked = throwsA(
  isA<StateError>().having(
    (error) => error.message,
    'message',
    contains('address is not allowed'),
  ),
);

class _Server {
  _Server(this._server);

  static Future<_Server> bind({String? redirectTo}) async {
    final server = _Server(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    final subscription = server._server.listen((request) async {
      server.paths.add(request.uri.path);
      server.referers.add(request.headers.value(HttpHeaders.refererHeader));
      if (redirectTo != null) {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, redirectTo);
      } else {
        request.response.add([1, 2, 3]);
      }
      await request.response.close();
    });
    addTearDown(() async {
      await subscription.cancel();
      await server._server.close(force: true);
    });
    return server;
  }

  final HttpServer _server;
  final paths = <String>[];
  final referers = <String?>[];

  int get port => _server.port;

  String url(String path) => 'http://127.0.0.1:$port$path';
}
