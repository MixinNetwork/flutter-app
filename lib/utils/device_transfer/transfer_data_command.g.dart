// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataCommand _$TransferDataCommandFromJson(Map<String, dynamic> json) =>
    TransferDataCommand(
      deviceId: json['device_id'] as String,
      action: json['action'] as String,
      version: (json['version'] as num).toInt(),
      ip: json['ip'] as String?,
      port: (json['port'] as num?)?.toInt(),
      secretKey: json['secret_key'] as String?,
      platform: json['platform'] as String? ?? 'desktop',
      code: (json['code'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TransferDataCommandToJson(
  TransferDataCommand instance,
) => <String, dynamic>{
  'device_id': instance.deviceId,
  'action': instance.action,
  'version': instance.version,
  'ip': instance.ip,
  'port': instance.port,
  'secret_key': instance.secretKey,
  'platform': instance.platform,
  'code': instance.code,
  'total': instance.total,
  'user_id': instance.userId,
  'progress': instance.progress,
};
