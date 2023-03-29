import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

part 'transfer_data_user.g.dart';

@JsonSerializable()
@UserRelationshipJsonConverter()
class TransferDataUser {
  TransferDataUser({
    required this.userId,
    required this.identityNumber,
    this.relationship,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.isVerified,
    this.createdAt,
    this.muteUntil,
    this.hasPin,
    this.appId,
    this.biography,
    this.isScam,
    this.codeUrl,
    this.codeId,
  });

  factory TransferDataUser.fromJson(Map<String, dynamic> json) =>
      _$TransferDataUserFromJson(json);

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'identity_number')
  final String identityNumber;

  @JsonKey(name: 'relationship')
  final UserRelationship? relationship;

  @JsonKey(name: 'full_name')
  final String? fullName;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  final String? phone;

  @JsonKey(name: 'is_verified')
  final bool? isVerified;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'mute_until')
  final DateTime? muteUntil;

  @JsonKey(name: 'has_pin')
  final int? hasPin;

  @JsonKey(name: 'app_id')
  final String? appId;

  final String? biography;

  @JsonKey(name: 'is_scam')
  final int? isScam;

  @JsonKey(name: 'code_url')
  final String? codeUrl;

  @JsonKey(name: 'code_id')
  final String? codeId;

  Map<String, dynamic> toJson() => _$TransferDataUserToJson(this);

  @override
  String toString() => 'TransferDataUser($userId)';
}
