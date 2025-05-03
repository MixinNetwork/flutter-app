// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_time_pre_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OneTimePreKey _$OneTimePreKeyFromJson(Map<String, dynamic> json) =>
    OneTimePreKey((json['key_id'] as num).toInt(), json['pub_key'] as String?);

Map<String, dynamic> _$OneTimePreKeyToJson(OneTimePreKey instance) =>
    <String, dynamic>{'key_id': instance.keyId, 'pub_key': instance.pubKey};
