import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rhttp/rhttp.dart' as rhttp;

import 'proxy.dart';

const _kMaxRedirects = 10;
const _kRedirectStatusCodes = {301, 302, 303, 307, 308};

final _hostName = RegExp(r'^[a-z0-9_-]+(\.[a-z0-9_-]+)*$');
final _numericLabel = RegExp(r'^([0-9]+|0x[0-9a-f]*)$');
// Letters of other scripts. IDNA keeps each of them outside ASCII, unlike,
// for example, full-width letters, which become the names or addresses that
// are not allowed.
// shortcut: names with other characters are rejected, also real ones; use an
// IDNA library if users need more scripts.
final _otherScriptLetters = RegExp(
  '['
  r'\u00C0-\u00D6\u00D8-\u00DE\u00E0-\u00F6\u00F8-\u00FF' // Latin-1
  r'\u0400-\u045F' // Cyrillic
  r'\u3041-\u3096\u30A1-\u30FA' // Hiragana and Katakana
  r'\u4E00-\u9FFF' // CJK ideographs
  r'\uAC00-\uD7A3' // Hangul
  ']',
);

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
  final proxyHosts = _proxyHosts(proxyConfig?.host);
  var target = uri;
  String? referer;
  for (var redirects = 0; redirects <= _kMaxRedirects; redirects++) {
    // The resolver lets proxy hosts through, so a URL must not name one.
    if (!isAllowed(target) ||
        _mayName(_normalizeHost(target.host), proxyHosts)) {
      throw StateError('NetworkImage address is not allowed');
    }
    final response = await (client ?? await _imageClient(proxyConfig)).send(
      http.Request('GET', target)
        ..followRedirects = false
        ..headers.addAll({...headers, HttpHeaders.refererHeader: ?referer}),
    );
    final location = response.headers[HttpHeaders.locationHeader];
    if (location == null ||
        !_kRedirectStatusCodes.contains(response.statusCode)) {
      return response;
    }
    await response.stream.listen((_) {}).cancel();
    // For the native client, "http:next.png" from an http URL is relative.
    final next = target.resolve(
      location.replaceFirst(
        RegExp('^${target.scheme}:', caseSensitive: false),
        '',
      ),
    );
    // As the native client does when it follows redirects itself.
    referer = target.isScheme('https') && next.isScheme('http')
        ? null
        : target.replace(userInfo: '').removeFragment().toString();
    target = next;
  }
  throw StateError('NetworkImage has too many redirects');
}

/// Whether [uri] is an http(s) URL that does not name a local address.
bool isPublicImageUri(Uri uri) {
  if (!uri.isScheme('http') && !uri.isScheme('https')) return false;
  final host = _normalizeHost(uri.host);

  final address = InternetAddress.tryParse(host);
  if (address != null) {
    // The native client reads "0177.0.0.1" as octal, so an IPv4 address must
    // have its canonical spelling.
    if (address.type == InternetAddressType.IPv4 && address.address != host) {
      return false;
    }
    return _isPublicAddress(address);
  }

  // The native client decodes escapes and applies IDNA, which can turn a host
  // into another name or into an IP address. "_" stands for the letters that
  // cannot, so the checks below stay in ASCII.
  final String asciiHost;
  try {
    asciiHost = Uri.decodeComponent(host).replaceAll(_otherScriptLetters, '_');
  } on FormatException {
    return false;
  }
  if (!_hostName.hasMatch(asciiHost)) return false;
  final lastLabel = asciiHost.split('.').last;
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
      _proxyHosts(proxyHost).contains(_normalizeHost(host));
  return [
    for (final address in addresses)
      if (isProxy || _isPublicAddress(address)) address.address,
  ];
}

/// The proxies that the client connects to. An app proxy replaces the ones of
/// the environment.
Set<String> _proxyHosts(String? appProxyHost) => appProxyHost != null
    ? {_normalizeHost(appProxyHost)}
    : _environmentProxyHosts();

Set<String> _environmentProxyHosts() => {
  for (final MapEntry(:key, :value) in imageEnvironment.entries)
    if (const {'http_proxy', 'https_proxy', 'all_proxy'}.contains(
      key.toLowerCase(),
    ))
      if (Uri.tryParse(value.contains('://') ? value : 'http://$value')
          case final proxy?)
        _normalizeHost(proxy.host),
};

/// Whether [host] may be one of [proxies]. A name in another script has a
/// Unicode and an "xn--" spelling, which need IDNA to compare, so two such
/// names count as equal.
bool _mayName(String host, Set<String> proxies) =>
    proxies.contains(host) || (_isIdn(host) && proxies.any(_isIdn));

// Uri.host has the other scripts percent-encoded.
bool _isIdn(String host) =>
    host.contains('%') ||
    host.codeUnits.any((unit) => unit > 0x7f) ||
    host.split('.').any((label) => label.startsWith('xn--'));

String _normalizeHost(String host) {
  final lower = host.toLowerCase();
  return lower.endsWith('.') ? lower.substring(0, lower.length - 1) : lower;
}

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
  // Documentation, 2001:db8::/32 and 3fff::/20, and benchmarking, 2001:2::/48.
  if (startsWith(const [0x20, 0x01, 0x0d, 0xb8]) ||
      (startsWith(const [0x3f, 0xff]) && bytes[2] & 0xf0 == 0) ||
      startsWith(const [0x20, 0x01, 0, 0x02, 0, 0])) {
    return false;
  }
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
      // Protocol assignments and the documentation ranges.
      (a == 192 && b == 0 && (c == 0 || c == 2)) ||
      (a == 198 && b == 51 && c == 100) ||
      (a == 203 && b == 0 && c == 113) ||
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
