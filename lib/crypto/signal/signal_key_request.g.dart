// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_key_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignalKeyRequest _$SignalKeyRequestFromJson(Map<String, dynamic> json) =>
    SignalKeyRequest(
      json['identity_key'] as String,
      SignedPreKey.fromJson(json['signed_pre_key'] as Map<String, dynamic>),
      (json['one_time_pre_keys'] as List<dynamic>)
          .map((e) => OneTimePreKey.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SignalKeyRequestToJson(
  SignalKeyRequest instance,
) => <String, dynamic>{
  'identity_key': instance.identityKey,
  'signed_pre_key': instance.signedPreKey.toJson(),
  'one_time_pre_keys': instance.oneTimePreKeys.map((e) => e.toJson()).toList(),
};
