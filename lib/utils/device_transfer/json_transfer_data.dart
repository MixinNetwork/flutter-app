import 'package:json_annotation/json_annotation.dart';

part 'json_transfer_data.g.dart';

const kTypeConversation = 'conversation';
const kTypeMessage = 'message';
const kTypeSticker = 'sticker';
const kTypeAsset = 'asset';
const kTypeSnapshot = 'snapshot';
const kTypeUser = 'user';
const kTypeCommand = 'command';

@JsonSerializable()
class JsonTransferData {
  JsonTransferData({
    required this.data,
    required this.type,
  });

  factory JsonTransferData.fromJson(Map<String, dynamic> json) =>
      _$JsonTransferDataFromJson(json);

  final Map<String, dynamic> data;
  final String type;

  Map<String, dynamic> toJson() => _$JsonTransferDataToJson(this);
}
