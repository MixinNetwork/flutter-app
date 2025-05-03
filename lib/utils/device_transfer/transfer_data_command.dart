import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_data_command.g.dart';

const kTransferCommandActionPull = 'pull';
const kTransferCommandActionPush = 'push';
const kTransferCommandActionFinish = 'finish';
const kTransferCommandActionConnect = 'connect';
const kTransferCommandActionStart = 'start';
const kTransferCommandActionClose = 'close';
const kTransferCommandActionProgress = 'progress';
const kTransferCommandActionCancel = 'cancel';

const kDeviceTransferProtocolVersion = 2;

@JsonSerializable()
class TransferDataCommand with EquatableMixin {
  TransferDataCommand({
    required this.deviceId,
    required this.action,
    required this.version,
    this.ip,
    this.port,
    this.secretKey,
    this.platform = 'desktop',
    this.code,
    this.total,
    this.userId,
    this.progress,
  });

  factory TransferDataCommand.fromJson(Map<String, dynamic> json) =>
      _$TransferDataCommandFromJson(json);

  factory TransferDataCommand.simple({
    required String deviceId,
    required String action,
  }) => TransferDataCommand(
    deviceId: deviceId,
    action: action,
    version: kDeviceTransferProtocolVersion,
  );

  factory TransferDataCommand.pull({required String deviceId}) =>
      TransferDataCommand.simple(
        deviceId: deviceId,
        action: kTransferCommandActionPull,
      );

  factory TransferDataCommand.push({
    required String ip,
    required int port,
    required String deviceId,
    required int code,
    required String secretKey,
  }) => TransferDataCommand(
    deviceId: deviceId,
    action: kTransferCommandActionPush,
    version: kDeviceTransferProtocolVersion,
    ip: ip,
    port: port,
    code: code,
    secretKey: secretKey,
  );

  factory TransferDataCommand.connect({
    required String deviceId,
    required int code,
    required String userId,
  }) => TransferDataCommand(
    deviceId: deviceId,
    action: kTransferCommandActionConnect,
    version: kDeviceTransferProtocolVersion,
    code: code,
    userId: userId,
  );

  factory TransferDataCommand.start({
    required String deviceId,
    required int total,
  }) => TransferDataCommand(
    deviceId: deviceId,
    action: kTransferCommandActionStart,
    version: kDeviceTransferProtocolVersion,
    total: total,
  );

  factory TransferDataCommand.progress({
    required String deviceId,
    required double progress,
  }) => TransferDataCommand(
    deviceId: deviceId,
    action: kTransferCommandActionProgress,
    version: kDeviceTransferProtocolVersion,
    progress: progress,
  );

  factory TransferDataCommand.cancel({required String deviceId}) =>
      TransferDataCommand(
        deviceId: deviceId,
        action: kTransferCommandActionCancel,
        version: kDeviceTransferProtocolVersion,
      );

  @JsonKey(name: 'device_id')
  final String deviceId;
  final String action;
  final int version;
  final String? ip;
  final int? port;
  @JsonKey(name: 'secret_key')
  final String? secretKey;

  @JsonKey(name: 'platform')
  final String platform;

  // verification number: 1 - 10000
  final int? code;

  final int? total;

  @JsonKey(name: 'user_id')
  final String? userId;

  @JsonKey(name: 'progress')
  final double? progress;

  Map<String, dynamic> toJson() => _$TransferDataCommandToJson(this);

  bool get isPull => action == kTransferCommandActionPull;

  @override
  List<Object?> get props => [
    deviceId,
    action,
    version,
    ip,
    port,
    secretKey,
    code,
    platform,
    total,
    userId,
    progress,
  ];
}
