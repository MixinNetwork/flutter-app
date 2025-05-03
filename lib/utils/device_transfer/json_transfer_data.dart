import 'package:json_annotation/json_annotation.dart';

part 'json_transfer_data.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum JsonTransferDataType {
  conversation,
  message,
  sticker,
  asset,
  token,
  snapshot,
  safeSnapshot,
  user,
  expiredMessage,
  transcriptMessage,
  participant,
  pinMessage,
  messageMention,
  app,
  inscriptionItem,
  inscriptionCollection,
  unknown,
}

@JsonSerializable()
class JsonTransferData {
  JsonTransferData({required this.data, required this.type});

  factory JsonTransferData.fromJson(Map<String, dynamic> json) =>
      _$JsonTransferDataFromJson(json);

  final Map<String, dynamic> data;

  @JsonKey(unknownEnumValue: JsonTransferDataType.unknown)
  final JsonTransferDataType type;

  Map<String, dynamic> toJson() => _$JsonTransferDataToJson(this);
}
