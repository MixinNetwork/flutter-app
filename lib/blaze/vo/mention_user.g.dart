// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mention_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MentionUser _$MentionUserFromJson(Map<String, dynamic> json) {
  return MentionUser(
    json['identity_number'] as String,
    json['full_name'] as String,
  );
}

Map<String, dynamic> _$MentionUserToJson(MentionUser instance) =>
    <String, dynamic>{
      'identity_number': instance.identityNumber,
      'full_name': instance.fullName,
    };
