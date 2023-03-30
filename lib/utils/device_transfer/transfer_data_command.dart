import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_data_command.g.dart';

const kTransferCommandActionPull = 'pull';
const kTransferCommandActionPush = 'push';
const kTransferCommandActionFinish = 'finish';
const kTransferCommandActionConnect = 'connect';

const _kVersion = 1;

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
  });

  factory TransferDataCommand.fromJson(Map<String, dynamic> json) =>
      _$TransferDataCommandFromJson(json);

  factory TransferDataCommand.pull({
    required String deviceId,
  }) =>
      TransferDataCommand(
        deviceId: deviceId,
        action: kTransferCommandActionPull,
        version: _kVersion,
      );

  factory TransferDataCommand.push({
    required String ip,
    required int port,
    required String deviceId,
    required int code,
  }) =>
      TransferDataCommand(
        deviceId: deviceId,
        action: kTransferCommandActionPush,
        version: _kVersion,
        ip: ip,
        port: port,
        code: code,
      );

  factory TransferDataCommand.connect({
    required String deviceId,
    required int code,
  }) =>
      TransferDataCommand(
        deviceId: deviceId,
        action: kTransferCommandActionConnect,
        version: _kVersion,
        code: code,
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

  // number: 1 - 10000
  final int? code;

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
      ];
}
