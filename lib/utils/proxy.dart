import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:rhttp/rhttp.dart' as rhttp;

import 'extension/extension.dart';

part 'proxy.g.dart';

enum ProxyType { http, socks5 }

@JsonSerializable()
class ProxyConfig with Equatable {
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
  String toString() => 'ProxyConfig(type: $type)';

  @override
  List<Object?> get props => [id, type, host, port, username, password];
}

extension DioProxyExt on Dio {
  void applyProxy(ProxyConfig? config) {
    i('apply client proxy: ${config != null}');
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
        findProxy = HttpClient.findProxyFromEnvironment;
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
        : null,
  );
  final client = await rhttp.RhttpCompatibleClient.create(settings: settings);
  _cachedClient = client;
  _cachedProxyConfig = proxyConfig;
  return client;
}

class _CustomHttpClientAdapterWrapper implements HttpClientAdapter {
  _CustomHttpClientAdapterWrapper(this.proxyConfig);

  final ProxyConfig? proxyConfig;

  // Created on first request so building a Dio client does not load rhttp.
  Future<rhttp.RhttpCompatibleClient>? _client;

  Future<rhttp.RhttpCompatibleClient> get client =>
      _client ??= createRHttpClient(proxyConfig: proxyConfig);

  @override
  void close({bool force = false}) {
    final client = _client;
    if (client == null) return;
    Future.sync(() async {
      (await client).close();
    });
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final adapter = AbortableHttpClientAdapter(await client);
    return adapter.fetch(options, requestStream, cancelFuture);
  }
}

Never _rethrowSendPortSafeError(Object error, StackTrace stackTrace) {
  // RhttpException.request can not send to other isolate by SendPort
  if (error is http.RequestAbortedException) {
    Error.throwWithStackTrace(
      http.RequestAbortedException(error.uri),
      stackTrace,
    );
  }
  if (error is rhttp.RhttpWrappedClientException) {
    Error.throwWithStackTrace(
      http.ClientException(error.message, error.uri),
      stackTrace,
    );
  }
  Error.throwWithStackTrace(error, stackTrace);
}

@visibleForTesting
class AbortableHttpClientAdapter implements HttpClientAdapter {
  AbortableHttpClientAdapter(this.client);

  final http.Client client;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final abortTrigger = cancelFuture?.then<void>((_) {}, onError: (_) {});
    final http.BaseRequest request;
    if (requestStream != null) {
      final streamedRequest = request = http.AbortableStreamedRequest(
        options.method,
        options.uri,
        abortTrigger: abortTrigger,
      );
      var closed = false;
      final sub = requestStream.listen(
        streamedRequest.sink.add,
        onError: streamedRequest.sink.addError,
        onDone: () {
          closed = true;
          unawaited(streamedRequest.sink.close());
        },
        cancelOnError: true,
      );
      if (abortTrigger != null) {
        unawaited(
          abortTrigger.whenComplete(() {
            if (closed) return;
            closed = true;
            unawaited(sub.cancel());
            unawaited(streamedRequest.sink.close());
          }),
        );
      }
    } else {
      request = http.AbortableRequest(
        options.method,
        options.uri,
        abortTrigger: abortTrigger,
      );
    }
    request.headers.addAll(
      Map.fromEntries(
        options.headers.entries.map(
          (e) => MapEntry(e.key, e.value.toString().trim()),
        ),
      ),
    );
    request
      ..followRedirects = options.followRedirects
      ..maxRedirects = options.maxRedirects
      ..persistentConnection = options.persistentConnection;

    final http.StreamedResponse response;
    try {
      response = await client.send(request);
    } catch (error, stackTrace) {
      _rethrowSendPortSafeError(error, stackTrace);
    }
    return ResponseBody(
      response.stream.cast<Uint8List>().handleError(_rethrowSendPortSafeError),
      response.statusCode,
      statusMessage: response.reasonPhrase,
      isRedirect: response.isRedirect,
      headers: Map.fromEntries(
        response.headers.entries.map((e) => MapEntry(e.key, [e.value])),
      ),
    );
  }

  @override
  void close({bool force = false}) => client.close();
}
