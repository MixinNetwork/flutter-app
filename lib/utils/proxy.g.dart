// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProxyConfig _$ProxyConfigFromJson(Map<String, dynamic> json) => ProxyConfig(
      type: $enumDecode(_$ProxyTypeEnumMap, json['type']),
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      id: json['id'] as String,
      username: json['username'] as String?,
      password: json['password'] as String?,
    );

Map<String, dynamic> _$ProxyConfigToJson(ProxyConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ProxyTypeEnumMap[instance.type]!,
      'host': instance.host,
      'port': instance.port,
      'username': instance.username,
      'password': instance.password,
    };

const _$ProxyTypeEnumMap = {
  ProxyType.http: 'http',
  ProxyType.socks5: 'socks5',
};
