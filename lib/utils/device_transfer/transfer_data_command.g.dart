// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataCommand _$TransferDataCommandFromJson(Map<String, dynamic> json) =>
    TransferDataCommand(
      deviceId: json['device_id'] as String,
      action: json['action'] as String,
      version: json['version'] as int,
      ip: json['ip'] as String?,
      port: json['port'] as int?,
      secretKey: json['secret_key'] as String?,
      platform: json['platform'] as String? ?? 'desktop',
      code: json['code'] as int?,
    );

Map<String, dynamic> _$TransferDataCommandToJson(
        TransferDataCommand instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'action': instance.action,
      'version': instance.version,
      'ip': instance.ip,
      'port': instance.port,
      'secret_key': instance.secretKey,
      'platform': instance.platform,
      'code': instance.code,
    };
