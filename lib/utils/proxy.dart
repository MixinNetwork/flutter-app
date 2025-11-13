import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_compatibility_layer/dio_compatibility_layer.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:rhttp/rhttp.dart' as rhttp;

import 'extension/extension.dart';

part 'proxy.g.dart';

enum ProxyType { http, socks5 }

@JsonSerializable()
class ProxyConfig with EquatableMixin {
  ProxyConfig({
    required this.type,
    required this.host,
    required this.port,
    required this.id,
    this.username,
    this.password,
  });

  factory ProxyConfig.fromJson(Map<String, dynamic> json) =>
      _$ProxyConfigFromJson(json);

  final String id;
  final ProxyType type;
  final String host;
  final int port;
  final String? username;
  final String? password;

  String toUri() {
    final scheme = type == ProxyType.http ? 'http' : 'socks5';
    final userInfo = !username.isNullOrBlank() && !password.isNullOrBlank()
        ? '$username:$password@'
        : '';
    return '$scheme://$userInfo$host:$port';
  }

  Map<String, dynamic> toJson() => _$ProxyConfigToJson(this);

  @override
  List<Object?> get props => [id, type, host, port, username, password];
}

extension DioProxyExt on Dio {
  void applyProxy(ProxyConfig? config) {
    i('apply client proxy ${config?.toUri()}');
    httpClientAdapter = _CustomHttpClientAdapterWrapper(config);
  }
}

extension HttpClientProxy on HttpClient {
  // for websocket proxy
  void setProxy(ProxyConfig? config) {
    switch (config) {
      case ProxyConfig(type: ProxyType.http):
        final proxyUrl = config.toUri();
        findProxy = (uri) => HttpClient.findProxyFromEnvironment(
          uri,
          environment: {'https_proxy': proxyUrl, 'http_proxy': proxyUrl},
        );
      case ProxyConfig(type: ProxyType.socks5):
      // not supported yet.
      case null:
        findProxy = null;
    }
  }
}

rhttp.RhttpCompatibleClient? _cachedClient;
ProxyConfig? _cachedProxyConfig;

Future<rhttp.RhttpCompatibleClient> createRHttpClient({
  ProxyConfig? proxyConfig,
}) async {
  if (_cachedProxyConfig == proxyConfig && _cachedClient != null) {
    return _cachedClient!;
  }

  final settings = rhttp.ClientSettings(
    proxySettings: proxyConfig != null
        ? rhttp.ProxySettings.proxy(proxyConfig.toUri())
        : const rhttp.ProxySettings.noProxy(),
  );
  final client = await rhttp.RhttpCompatibleClient.create(settings: settings);
  _cachedClient = client;
  _cachedProxyConfig = proxyConfig;
  return client;
}

class _CustomHttpClientAdapterWrapper implements HttpClientAdapter {
  _CustomHttpClientAdapterWrapper(ProxyConfig? proxyConfig)
    : client = createRHttpClient(proxyConfig: proxyConfig);

  final Future<rhttp.RhttpCompatibleClient> client;

  @override
  void close({bool force = false}) {
    Future.sync(() async {
      final client = await this.client;
      client.close();
    });
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    try {
      final adapter = ConversionLayerAdapter(await client);
      final resp = await adapter.fetch(options, requestStream, cancelFuture);
      return resp;
    } on rhttp.RhttpWrappedClientException catch (error, stackTrace) {
      // RhttpException.request can not send to other isolate by SendPort
      Error.throwWithStackTrace(
        http.ClientException(error.message, error.uri),
        stackTrace,
      );
    }
  }
}
