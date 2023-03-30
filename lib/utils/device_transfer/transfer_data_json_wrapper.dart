import 'package:json_annotation/json_annotation.dart';

part 'transfer_data_json_wrapper.g.dart';

const kTypeConversation = 'conversation';
const kTypeMessage = 'message';
const kTypeSticker = 'sticker';
const kTypeAsset = 'asset';
const kTypeSnapshot = 'snapshot';
const kTypeUser = 'user';
const kTypeCommand = 'command';


@JsonSerializable()
class TransferDataJsonWrapper {
  TransferDataJsonWrapper({
    required this.data,
    required this.type,
  });

  factory TransferDataJsonWrapper.fromJson(Map<String, dynamic> json) =>
      _$TransferDataJsonWrapperFromJson(json);

  final Map<String, dynamic> data;
  final String type;

  Map<String, dynamic> toJson() => _$TransferDataJsonWrapperToJson(this);
}
