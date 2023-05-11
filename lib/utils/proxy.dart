import 'dart:io';

import 'package:dio/io.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import 'extension/extension.dart';
import 'property/setting_property.dart';

part 'proxy.g.dart';

enum ProxyType {
  http,
  socks5,
}

@JsonSerializable()
class ProxyConfig {
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

}

extension ClientExt on Client {
  void configProxySetting(SettingPropertyStorage settingProperties) {
    var proxyUrl = settingProperties.activatedProxyUrl;
    settingProperties.addListener(() {
      final url = settingProperties.activatedProxyUrl;
      if (url != proxyUrl) {
        proxyUrl = url;
        _applyProxy(url);
      }
    });
    _applyProxy(proxyUrl);
  }

  void _applyProxy(String? proxyUrl) {
    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      i('apply client proxy $proxyUrl');
      dio.httpClientAdapter = IOHttpClientAdapter();
      (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
          (client) => client..setProxy(proxyUrl);
    } else {
      i('remove client proxy');
      dio.httpClientAdapter = IOHttpClientAdapter();
    }
  }
}

extension HttpClientProxy on HttpClient {
  void setProxy(String? proxyUrl) {
    if (proxyUrl == null || proxyUrl.isEmpty) {
      findProxy = null;
    } else {
      findProxy = (url) => HttpClient.findProxyFromEnvironment(
            url,
            environment: {
              if (proxyUrl.startsWith('http')) ...{
                'https_proxy': proxyUrl,
                'http_proxy': proxyUrl,
              },
              if (proxyUrl.startsWith('socks5')) 'socks_proxy': proxyUrl,
            },
          );
    }
  }
}
