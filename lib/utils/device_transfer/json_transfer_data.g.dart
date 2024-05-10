// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_transfer_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JsonTransferData _$JsonTransferDataFromJson(Map<String, dynamic> json) =>
    JsonTransferData(
      data: json['data'] as Map<String, dynamic>,
      type: $enumDecode(_$JsonTransferDataTypeEnumMap, json['type'],
          unknownValue: JsonTransferDataType.unknown),
    );

Map<String, dynamic> _$JsonTransferDataToJson(JsonTransferData instance) =>
    <String, dynamic>{
      'data': instance.data,
      'type': _$JsonTransferDataTypeEnumMap[instance.type]!,
    };

const _$JsonTransferDataTypeEnumMap = {
  JsonTransferDataType.conversation: 'conversation',
  JsonTransferDataType.message: 'message',
  JsonTransferDataType.sticker: 'sticker',
  JsonTransferDataType.asset: 'asset',
  JsonTransferDataType.token: 'token',
  JsonTransferDataType.snapshot: 'snapshot',
  JsonTransferDataType.safeSnapshot: 'safe_snapshot',
  JsonTransferDataType.user: 'user',
  JsonTransferDataType.expiredMessage: 'expired_message',
  JsonTransferDataType.transcriptMessage: 'transcript_message',
  JsonTransferDataType.participant: 'participant',
  JsonTransferDataType.pinMessage: 'pin_message',
  JsonTransferDataType.messageMention: 'message_mention',
  JsonTransferDataType.app: 'app',
  JsonTransferDataType.inscriptionItem: 'inscription_item',
  JsonTransferDataType.inscriptionCollection: 'inscription_collection',
  JsonTransferDataType.unknown: 'unknown',
};
