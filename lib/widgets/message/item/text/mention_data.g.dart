// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mention_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MentionData _$MentionDataFromJson(Map<String, dynamic> json) {
  return MentionData(
    json['identity_number'] as String,
    json['full_name'] as String,
  );
}

Map<String, dynamic> _$MentionDataToJson(MentionData instance) =>
    <String, dynamic>{
      'identity_number': instance.identityNumber,
      'full_name': instance.fullName,
    };
