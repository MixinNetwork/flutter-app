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
      total: json['total'] as int?,
      userId: json['user_id'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TransferDataCommandToJson(TransferDataCommand instance) {
  final val = <String, dynamic>{
    'device_id': instance.deviceId,
    'action': instance.action,
    'version': instance.version,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('ip', instance.ip);
  writeNotNull('port', instance.port);
  writeNotNull('secret_key', instance.secretKey);
  val['platform'] = instance.platform;
  writeNotNull('code', instance.code);
  writeNotNull('total', instance.total);
  writeNotNull('user_id', instance.userId);
  writeNotNull('progress', instance.progress);
  return val;
}
