import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../db/mixin_database.dart' as db;

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
    this.membership,
  });

  factory TransferDataUser.fromJson(Map<String, dynamic> json) =>
      _$TransferDataUserFromJson(json);

  factory TransferDataUser.fromDbUser(db.User user) => TransferDataUser(
    userId: user.userId,
    identityNumber: user.identityNumber,
    relationship: user.relationship,
    fullName: user.fullName,
    avatarUrl: user.avatarUrl,
    phone: user.phone,
    isVerified: user.isVerified,
    createdAt: user.createdAt,
    muteUntil: user.muteUntil,
    hasPin: user.hasPin == 1,
    appId: user.appId,
    biography: user.biography ?? '',
    isScam: user.isScam == 1,
    codeUrl: user.codeUrl,
    codeId: user.codeId,
    membership: user.membership,
  );

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
  final bool? hasPin;

  @JsonKey(name: 'app_id')
  final String? appId;

  final String? biography;

  @JsonKey(name: 'is_scam')
  final bool? isScam;

  @JsonKey(name: 'code_url')
  final String? codeUrl;

  @JsonKey(name: 'code_id')
  final String? codeId;

  @JsonKey(name: 'membership')
  final Membership? membership;

  Map<String, dynamic> toJson() => _$TransferDataUserToJson(this);

  db.User toDbUser() => db.User(
    userId: userId,
    identityNumber: identityNumber,
    relationship: relationship,
    fullName: fullName,
    avatarUrl: avatarUrl,
    phone: phone,
    isVerified: isVerified,
    createdAt: createdAt,
    muteUntil: muteUntil,
    hasPin: hasPin == true ? 1 : 0,
    appId: appId,
    biography: biography,
    isScam: isScam == true ? 1 : 0,
    codeUrl: codeUrl,
    codeId: codeId,
    membership: membership,
  );

  @override
  String toString() => 'TransferDataUser($userId)';
}
