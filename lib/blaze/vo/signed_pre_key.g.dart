// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signed_pre_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedPreKey _$SignedPreKeyFromJson(Map<String, dynamic> json) => SignedPreKey(
  (json['key_id'] as num).toInt(),
  json['pub_key'] as String?,
  json['signature'] as String,
);

Map<String, dynamic> _$SignedPreKeyToJson(SignedPreKey instance) =>
    <String, dynamic>{
      'key_id': instance.keyId,
      'pub_key': instance.pubKey,
      'signature': instance.signature,
    };
