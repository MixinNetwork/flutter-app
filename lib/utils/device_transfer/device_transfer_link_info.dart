import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_transfer_link_info.g.dart';

@JsonSerializable()
class DeviceTransferLinkInfo with EquatableMixin {
  DeviceTransferLinkInfo({
    required this.version,
    required this.ip,
    required this.port,
    required this.deviceId,
  });

  factory DeviceTransferLinkInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceTransferLinkInfoFromJson(json);

  final String version;
  final String ip;
  final int port;

  @JsonKey(name: 'device_id')
  final String deviceId;

  Map<String, dynamic> toJson() => _$DeviceTransferLinkInfoToJson(this);

  @override
  List<Object?> get props => [
        version,
        ip,
        port,
        deviceId,
      ];
}
