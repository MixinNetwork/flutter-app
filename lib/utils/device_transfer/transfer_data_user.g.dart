// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataUser _$TransferDataUserFromJson(Map<String, dynamic> json) =>
    TransferDataUser(
      userId: json['user_id'] as String,
      identityNumber: json['identity_number'] as String,
      relationship: const UserRelationshipJsonConverter().fromJson(
        json['relationship'] as String?,
      ),
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      isVerified: json['is_verified'] as bool?,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      muteUntil:
          json['mute_until'] == null
              ? null
              : DateTime.parse(json['mute_until'] as String),
      hasPin: json['has_pin'] as bool?,
      appId: json['app_id'] as String?,
      biography: json['biography'] as String?,
      isScam: json['is_scam'] as bool?,
      codeUrl: json['code_url'] as String?,
      codeId: json['code_id'] as String?,
      membership:
          json['membership'] == null
              ? null
              : Membership.fromJson(json['membership'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TransferDataUserToJson(TransferDataUser instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'identity_number': instance.identityNumber,
      'relationship': const UserRelationshipJsonConverter().toJson(
        instance.relationship,
      ),
      'full_name': instance.fullName,
      'avatar_url': instance.avatarUrl,
      'phone': instance.phone,
      'is_verified': instance.isVerified,
      'created_at': instance.createdAt?.toIso8601String(),
      'mute_until': instance.muteUntil?.toIso8601String(),
      'has_pin': instance.hasPin,
      'app_id': instance.appId,
      'biography': instance.biography,
      'is_scam': instance.isScam,
      'code_url': instance.codeUrl,
      'code_id': instance.codeId,
      'membership': instance.membership?.toJson(),
    };
