// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignalKey _$SignalKeyFromJson(Map<String, dynamic> json) => SignalKey(
      json['identity_key'] as String,
      SignedPreKey.fromJson(json['signed_pre_key'] as Map<String, dynamic>),
      OneTimePreKey.fromJson(json['one_time_pre_key'] as Map<String, dynamic>),
      (json['registration_id'] as num).toInt(),
      json['user_id'] as String,
      json['session_id'] as String,
    );

Map<String, dynamic> _$SignalKeyToJson(SignalKey instance) => <String, dynamic>{
      'identity_key': instance.identityKey,
      'signed_pre_key': instance.signedPreKey.toJson(),
      'one_time_pre_key': instance.preKey.toJson(),
      'registration_id': instance.registrationId,
      'user_id': instance.userId,
      'session_id': instance.sessionId,
    };
