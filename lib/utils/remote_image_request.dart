import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rhttp/rhttp.dart' as rhttp;

import 'proxy.dart';

const _kMaxRedirects = 10;
const _kRedirectStatusCodes = {301, 302, 303, 307, 308};

final _hostName = RegExp(r'^[a-z0-9_-]+(\.[a-z0-9_-]+)*$');
final _numericLabel = RegExp(r'^([0-9]+|0x[0-9a-f]*)$');

typedef HostLookup = Future<List<InternetAddress>> Function(String host);

@visibleForTesting
HostLookup imageHostLookup = InternetAddress.lookup;

@visibleForTesting
Map<String, String> imageEnvironment = Platform.environment;

/// GETs an image. Image URLs come from remote content, so the URL, each
/// redirect and each resolved address must be public.
// shortcut: a proxy that gets host names (HTTP, or socks5h from the
// environment) resolves them, so behind one only the URL is checked; check
// addresses too if the app gets a proxy that reports them.
Future<http.StreamedResponse> sendImageRequest(
  Uri uri, {
  ProxyConfig? proxyConfig,
  Map<String, String> headers = const {},
  @visibleForTesting bool Function(Uri uri) isAllowed = isPublicImageUri,
  // Unit tests cannot load the native client.
  @visibleForTesting http.Client? client,
}) async {
  var target = uri;
  for (var redirects = 0; redirects <= _kMaxRedirects; redirects++) {
    if (!isAllowed(target) || target.host == proxyConfig?.host.toLowerCase()) {
      throw StateError('NetworkImage address is not allowed');
    }
    final response = await (client ?? await _imageClient(proxyConfig)).send(
      http.Request('GET', target)
        ..followRedirects = false
        ..headers.addAll(headers),
    );
    final location = response.headers[HttpHeaders.locationHeader];
    if (location == null ||
        !_kRedirectStatusCodes.contains(response.statusCode)) {
      return response;
    }
    await response.stream.listen((_) {}).cancel();
    target = target.resolve(location);
  }
  throw StateError('NetworkImage has too many redirects');
}

/// Whether [uri] is an http(s) URL that does not name a local address.
bool isPublicImageUri(Uri uri) {
  if (!uri.isScheme('http') && !uri.isScheme('https')) return false;
  var host = uri.host.toLowerCase();
  if (host.endsWith('.')) host = host.substring(0, host.length - 1);

  final address = InternetAddress.tryParse(host);
  if (address != null) {
    // The native client reads "0177.0.0.1" as octal, so an IPv4 address must
    // have its canonical spelling.
    if (address.type == InternetAddressType.IPv4 && address.address != host) {
      return false;
    }
    return _isPublicAddress(address);
  }

  // Rejects escaped and non-ASCII hosts, which the native client maps to
  // other names, such as full-width digits to an IP address.
  if (!_hostName.hasMatch(host)) return false;
  // The resolver lets proxy hosts through, so a URL must not name one.
  if (_environmentProxyHosts().contains(host)) return false;
  final lastLabel = host.split('.').last;
  // The native client reads a name that ends in a number, such as "127.1", as
  // an IPv4 address and connects without a DNS lookup.
  // ".local" names are mDNS devices, which also have public IPv6 addresses.
  return lastLabel != 'localhost' &&
      lastLabel != 'local' &&
      !_numericLabel.hasMatch(lastLabel);
}

/// The DNS resolver of the image client, when no HTTP proxy resolves for it.
@visibleForTesting
Future<List<String>> resolveImageHost(
  String host, {
  String? proxyHost,
  HostLookup? lookup,
}) async {
  final List<InternetAddress> addresses;
  try {
    addresses = await (lookup ?? imageHostLookup)(host);
  } on SocketException {
    return const [];
  }
  // Proxies are resolved here too. An image URL cannot name them.
  final isProxy =
      host == 'localhost' ||
      host == proxyHost?.toLowerCase() ||
      _environmentProxyHosts().contains(host);
  return [
    for (final address in addresses)
      if (isProxy || _isPublicAddress(address)) address.address,
  ];
}

Set<String> _environmentProxyHosts() => {
  for (final MapEntry(:key, :value) in imageEnvironment.entries)
    if (const {'http_proxy', 'https_proxy', 'all_proxy'}.contains(
      key.toLowerCase(),
    ))
      ?Uri.tryParse(value.contains('://') ? value : 'http://$value')?.host,
};

bool _isPublicAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (bytes.length == 4) return _isPublicIPv4(bytes);

  bool startsWith(List<int> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }

  // IPv4 inside IPv6: mapped, NAT64 (IPv6-only networks, also the local-use
  // prefix of RFC 8215 as a /96) and 6to4.
  if (startsWith(const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff]) ||
      startsWith(const [0, 0x64, 0xff, 0x9b, 0, 0, 0, 0, 0, 0, 0, 0]) ||
      startsWith(const [0, 0x64, 0xff, 0x9b, 0, 1, 0, 0, 0, 0, 0, 0])) {
    return _isPublicIPv4(bytes.sublist(12));
  }
  if (startsWith(const [0x20, 0x02])) return _isPublicIPv4(bytes.sublist(2, 6));
  // Only global unicast, 2000::/3.
  return bytes[0] & 0xe0 == 0x20;
}

// 198.18.0.0/15 stays allowed: fake-IP proxies such as Clash and Surge answer
// DNS queries with it.
bool _isPublicIPv4(Uint8List bytes) {
  final [a, b, c, _] = bytes;
  return !(a == 0 ||
      a == 10 ||
      a == 127 ||
      (a == 100 && b & 0xc0 == 64) ||
      (a == 169 && b == 254) ||
      (a == 172 && b & 0xf0 == 16) ||
      (a == 192 && b == 168) ||
      (a == 192 && b == 0 && c == 0) ||
      a >= 224);
}

rhttp.RhttpCompatibleClient? _cachedClient;
ProxyConfig? _cachedProxyConfig;

Future<rhttp.RhttpCompatibleClient> _imageClient(
  ProxyConfig? proxyConfig,
) async {
  if (_cachedProxyConfig == proxyConfig && _cachedClient != null) {
    return _cachedClient!;
  }

  final client = await rhttp.RhttpCompatibleClient.create(
    settings: imageClientSettings(proxyConfig),
  );
  _cachedClient = client;
  _cachedProxyConfig = proxyConfig;
  return client;
}

@visibleForTesting
rhttp.ClientSettings imageClientSettings(ProxyConfig? proxyConfig) =>
    rhttp.ClientSettings(
      // Followed by hand, to check each target.
      redirectSettings: const rhttp.RedirectSettings.none(),
      proxySettings: proxyConfig != null
          ? rhttp.ProxySettings.proxy(proxyConfig.toUri())
          : null,
      // An HTTP proxy gets host names. A SOCKS5 proxy gets addresses, so the
      // app resolves them, as it does with no proxy.
      dnsSettings: proxyConfig?.type == ProxyType.http
          ? null
          : rhttp.DnsSettings.dynamic(
              resolver: (host) async {
                final addresses = await resolveImageHost(
                  host,
                  proxyHost: proxyConfig?.host,
                );
                // With no address, reqwest gives a SOCKS5 proxy, also one from
                // the environment, the name to resolve. A connection to the
                // broadcast address always fails.
                return addresses.isEmpty
                    ? const ['255.255.255.255']
                    : addresses;
              },
            ),
    );
