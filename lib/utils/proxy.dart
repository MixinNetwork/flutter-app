import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../ui/provider/setting_provider.dart';
import 'extension/extension.dart';

part 'proxy.g.dart';

enum ProxyType {
  http,
  socks5,
}

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
    if (config != null) {
      i('apply client proxy $config');
      httpClientAdapter = IOHttpClientAdapter();
      (httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          () => HttpClient()..setProxy(config);
    } else {
      i('remove client proxy');
      httpClientAdapter = IOHttpClientAdapter();
    }
  }
}

extension ClientExt on Client {
  void configProxySetting(AppSettingKeyValue settingKeyValue) {
    var proxyConfig = settingKeyValue.activatedProxy;
    settingKeyValue.addListener(() {
      final config = settingKeyValue.activatedProxy;
      if (config != proxyConfig) {
        proxyConfig = config;
        dio.applyProxy(config);
      }
    });
    dio.applyProxy(proxyConfig);
  }
}

extension HttpClientProxy on HttpClient {
  void setProxy(ProxyConfig? config) {
    switch (config) {
      case ProxyConfig(type: ProxyType.http):
        final proxyUrl = config.toUri();
        findProxy = (uri) => HttpClient.findProxyFromEnvironment(
              uri,
              environment: {
                'https_proxy': proxyUrl,
                'http_proxy': proxyUrl,
              },
            );
      case ProxyConfig(type: ProxyType.socks5):
      // not supported yet.
      case null:
        findProxy = null;
    }
  }
}
