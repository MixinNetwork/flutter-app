// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_transfer_link_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceTransferLinkInfo _$DeviceTransferLinkInfoFromJson(
        Map<String, dynamic> json) =>
    DeviceTransferLinkInfo(
      version: json['version'] as String,
      ip: json['ip'] as String,
      port: json['port'] as int,
      deviceId: json['device_id'] as String,
    );

Map<String, dynamic> _$DeviceTransferLinkInfoToJson(
        DeviceTransferLinkInfo instance) =>
    <String, dynamic>{
      'version': instance.version,
      'ip': instance.ip,
      'port': instance.port,
      'device_id': instance.deviceId,
    };
