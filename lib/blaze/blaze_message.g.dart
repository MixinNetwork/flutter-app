// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessage _$BlazeMessageFromJson(Map<String, dynamic> json) => BlazeMessage(
      id: json['id'] as String,
      action: json['action'] as String,
      data: json['data'],
      params: json['params'],
      error: json['error'] == null
          ? null
          : MixinError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BlazeMessageToJson(BlazeMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'params': dynamicToJson(instance.params),
      'data': dynamicToJson(instance.data),
      'error': instance.error?.toJson(),
    };
