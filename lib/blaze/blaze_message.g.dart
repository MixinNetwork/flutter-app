// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessage _$BlazeMessageFromJson(Map<String, dynamic> json) {
  return BlazeMessage(
    id: json['id'] as String,
    action: json['action'] as String,
    data: json['data'] as Map<String, dynamic>,
    params: json['params'],
  );
}

Map<String, dynamic> _$BlazeMessageToJson(BlazeMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'params': instance.params,
      'data': instance.data,
    };
