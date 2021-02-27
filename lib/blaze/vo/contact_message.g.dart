// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactMessage _$ContactMessageFromJson(Map<String, dynamic> json) {
  $checkKeys(json, disallowNullValues: const ['user_id']);
  return ContactMessage(
    json['user_id'] as String,
  );
}

Map<String, dynamic> _$ContactMessageToJson(ContactMessage instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
    };
