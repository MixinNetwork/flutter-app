import 'dart:convert';
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

  // A proxy of the machine that runs the tests must not change them.
  final environment = imageEnvironment;
  setUp(() => imageEnvironment = {});
  tearDown(() => imageEnvironment = environment);

  /// Whether the request for [url] goes out.
  Future<bool> isSent(String url, {ProxyConfig? proxy}) async {
    var sent = false;
    await sendImageRequest(
      Uri.parse(url),
      proxyConfig: proxy,
      client: MockClient((_) async {
        sent = true;
        return http.Response('ok', 200);
      }),
    ).then<void>(
      (_) {},
      // Anything but the address check fails the test.
      onError: (Object error) => expect(
        error,
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('address is not allowed'),
        ),
      ),
    );
    return sent;
  }

  ProxyConfig appProxy(ProxyType type) =>
      ProxyConfig(type: type, host: 'app.proxy', port: 1080, id: 'proxy');

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
      // Globally reachable parts of 2001::/23, and the block after it.
      'http://[2001:1::1]/a.png',
      'http://[2001:1::2]/a.png',
      'http://[2001:1::3]/a.png',
      'http://[2001:3::1]/a.png',
      'http://[2001:3:ffff::1]/a.png',
      'http://[2001:4:112::1]/a.png',
      'http://[2001:20::1]/a.png',
      'http://[2001:2f:ffff::1]/a.png',
      'http://[2001:30::1]/a.png',
      'http://[2001:3f:ffff::1]/a.png',
      'http://[2001:200::1]/a.png',
      'http://[3fff:1000::1]/a.png',
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
      // The rest of the IETF protocol assignments, 2001::/23.
      'http://[2001::1]/a.png',
      'http://[2001:1::]/a.png',
      'http://[2001:1::4]/a.png',
      'http://[2001:1:0:1::1]/a.png',
      'http://[2001:4:111::1]/a.png',
      'http://[2001:4:113::1]/a.png',
      'http://[2001:10::1]/a.png',
      'http://[2001:40::1]/a.png',
      'http://[2001:100::1]/a.png',
      'http://[2001:1ff:ffff::1]/a.png',
      'http://[2001:103::1]/a.png',
      'http://[3fff::1]/a.png',
      'http://[3fff:fff:ffff::1]/a.png',
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

  test('an image URL cannot name an environment proxy', () async {
    imageEnvironment = {'HTTPS_PROXY': 'http://Proxy.lan:7890'};

    expect(await isSent('http://proxy.lan:8080/a'), isFalse);
    expect(await isSent('http://proxy.lan./a'), isFalse);
    expect(await isSent('http://other.lan/a'), isTrue);

    imageEnvironment = {'HTTP_PROXY': 'http://proxy.lan.:7890'};
    expect(await isSent('http://proxy.lan/a'), isFalse);
    expect(await isSent('http://proxy.lan./a'), isFalse);
  });

  // The two spellings of a name in another script cannot be compared without
  // IDNA, which the native client applies.
  for (final (proxy, url) in [
    ('xn--bcher-kva.lan', 'http://bücher.lan/a'),
    ('XN--BCHER-KVA.lan', 'http://bücher.lan/a'),
    ('bücher.lan', 'http://BÜCHER.lan/a'),
    ('bücher.lan', 'http://xn--bcher-kva.lan/a'),
  ]) {
    test('the image URL $url may name the environment proxy $proxy', () async {
      imageEnvironment = {'HTTP_PROXY': 'http://$proxy:7890'};

      expect(await isSent(url), isFalse);
      expect(await isSent('http://images.example/a'), isTrue);
    });
  }

  test(
    'names in other scripts load next to a proxy with an ASCII name',
    () async {
      imageEnvironment = {'HTTP_PROXY': 'http://proxy.lan:7890'};

      expect(await isSent('http://bücher.example/a'), isTrue);
      expect(await isSent('http://xn--bcher-kva.example/a'), isTrue);
    },
  );

  // The native client does not use the environment next to an app proxy.
  for (final type in ProxyType.values) {
    test('a ${type.name} app proxy replaces the environment proxies', () async {
      imageEnvironment = {'HTTPS_PROXY': 'http://xn--bcher-kva.lan:7890'};
      expect(
        await isSent('http://例え.example/a', proxy: appProxy(type)),
        isTrue,
      );

      imageEnvironment = {'HTTPS_PROXY': 'http://env.proxy:7890'};
      expect(await isSent('http://env.proxy/a', proxy: appProxy(type)), isTrue);
      Future<List<InternetAddress>> private(String _) async => [
        InternetAddress('192.168.1.2'),
      ];
      expect(
        await resolveImageHost(
          'env.proxy',
          proxyHost: 'app.proxy',
          lookup: private,
        ),
        isEmpty,
      );
      expect(
        await resolveImageHost(
          'app.proxy',
          proxyHost: 'App.Proxy.',
          lookup: private,
        ),
        ['192.168.1.2'],
      );
    });
  }

  // Only a client with the resolver lets a proxy host through. With an HTTP
  // proxy, the proxy gets the names.
  test('a URL may name an HTTP app proxy', () async {
    expect(
      await isSent('http://app.proxy/a', proxy: appProxy(ProxyType.http)),
      isTrue,
    );
    expect(
      await isSent(
        'http://例え.example/a',
        proxy: ProxyConfig(
          type: ProxyType.http,
          host: 'xn--bcher-kva.example',
          port: 1080,
          id: 'proxy',
        ),
      ),
      isTrue,
    );
    // The URL rules still apply.
    expect(
      await isSent('http://127.0.0.1/a', proxy: appProxy(ProxyType.http)),
      isFalse,
    );
    expect(
      await isSent('http://nas.local/a', proxy: appProxy(ProxyType.http)),
      isFalse,
    );
  });

  test('the resolver lets an environment proxy through', () async {
    imageEnvironment = {'HTTP_PROXY': 'http://proxy.lan.:7890'};

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
    ('http://bücher.lan:8080/a.png', 'bücher.lan'),
    ('http://bücher.lan:8080/a.png', 'xn--bcher-kva.lan'),
    ('http://xn--bcher-kva.lan:8080/a.png', 'bücher.lan'),
  ]) {
    test('the image URL $url cannot name the app proxy $proxyHost', () async {
      await expectLater(
        sendImageRequest(
          Uri.parse(url),
          proxyConfig: ProxyConfig(
            type: ProxyType.socks5,
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

  // The native client reads these as relative to the previous URL.
  for (final (location, path) in [
    ('http:next.png', '/gallery/next.png'),
    ('HTTP:next.png', '/gallery/next.png'),
    ('http:/root.png', '/root.png'),
  ]) {
    test('the redirect to $location stays on the server', () async {
      final server = await _Server.bind(redirectTo: location, once: true);

      final response = await sendImageRequest(
        Uri.parse(server.url('/gallery/a.png')),
        isAllowed: (uri) => uri.host == '127.0.0.1' && uri.port == server.port,
        client: client(),
      );
      await response.stream.drain<void>();

      expect(server.paths, ['/gallery/a.png', path]);
    });
  }

  // The native client sends the credentials of the URL as a header, and keeps
  // it on redirects that stay on the same origin.
  for (final (name, location) in <(String, String Function(_Server))>[
    ('an absolute', (server) => server.url('/b.png')),
    ('a relative', (_) => '/b.png'),
    // The native client ignores these.
    (
      'a "user info"',
      (server) => 'http://other:secret@127.0.0.1:${server.port}/b.png',
    ),
  ]) {
    test('$name redirect on the same origin keeps the credentials', () async {
      late final _Server server;
      server = await _Server.bind(
        redirect: (path) => path == '/a.png' ? location(server) : null,
      );

      final response = await sendImageRequest(
        Uri.parse('http://user:pw@127.0.0.1:${server.port}/a.png'),
        isAllowed: (_) => true,
        client: client(),
      );
      await response.stream.drain<void>();

      expect(server.paths, ['/a.png', '/b.png']);
      expect(server.authorizations, [_basicUserPw, _basicUserPw]);
      expect(server.referers.last, server.url('/a.png'));
    });
  }

  test('credentials do not go to another origin, nor come back', () async {
    late final _Server first;
    final other = await _Server.bind(
      redirect: (_) => first.url('/c.png'),
    );
    first = await _Server.bind(
      redirect: (path) => path == '/a.png' ? other.url('/b.png') : null,
    );

    final response = await sendImageRequest(
      Uri.parse('http://user:pw@127.0.0.1:${first.port}/a.png'),
      isAllowed: (_) => true,
      client: client(),
    );
    await response.stream.drain<void>();

    expect(first.paths, ['/a.png', '/c.png']);
    expect(first.authorizations, [_basicUserPw, null]);
    expect(other.authorizations, [null]);
  });

  // Another scheme or host is another origin, also with the same port.
  for (final (location, expected) in [
    ('https://images.example:8443/b', 'https://images.example:8443/b'),
    ('http://other.example:8443/b', 'http://other.example:8443/b'),
    ('http://images.example:8444/b', 'http://images.example:8444/b'),
    ('http://other:secret@other.example:8443/b', 'http://other.example:8443/b'),
  ]) {
    test('credentials do not follow a redirect to $location', () async {
      final sent = <Uri>[];
      await sendImageRequest(
        Uri.parse('http://user:pw@images.example:8443/a'),
        client: MockClient((request) async {
          sent.add(request.url);
          return sent.length == 1
              ? http.Response('', 302, headers: {'location': location})
              : http.Response('ok', 200);
        }),
      );

      expect(sent.last, Uri.parse(expected));
    });
  }

  test(
    'same-origin IPv6 redirect with another spelling keeps credentials',
    () async {
      final sent = <Uri>[];
      await sendImageRequest(
        Uri.parse('https://user:pw@[2606:4700:0:0:0:0:0:1]/a'),
        client: MockClient((request) async {
          sent.add(request.url);
          return sent.length == 1
              ? http.Response(
                  '',
                  302,
                  headers: {'location': 'https://[2606:4700::1]/b'},
                )
              : http.Response('ok', 200);
        }),
      );

      expect(sent.last, Uri.parse('https://user:pw@[2606:4700::1]/b'));
    },
  );

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

final _basicUserPw = 'Basic ${base64Encode(utf8.encode('user:pw'))}';

final throwsBlocked = throwsA(
  isA<StateError>().having(
    (error) => error.message,
    'message',
    contains('address is not allowed'),
  ),
);

class _Server {
  _Server(this._server);

  static Future<_Server> bind({
    String? redirectTo,
    bool once = false,
    String? Function(String path)? redirect,
  }) async {
    final server = _Server(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    final subscription = server._server.listen((request) async {
      server.paths.add(request.uri.path);
      server.referers.add(request.headers.value(HttpHeaders.refererHeader));
      server.authorizations.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      final next = redirect != null
          ? redirect(request.uri.path)
          : (!once || server.paths.length == 1 ? redirectTo : null);
      if (next != null) {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, next);
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
  final authorizations = <String?>[];

  int get port => _server.port;

  String url(String path) => 'http://127.0.0.1:$port$path';
}
