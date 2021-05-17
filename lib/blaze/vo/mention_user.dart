import 'package:json_annotation/json_annotation.dart';

part 'mention_user.g.dart';

@JsonSerializable()
class MentionUser {
  MentionUser(this.identityNumber, this.fullName);

  factory MentionUser.fromJson(Map<String, dynamic> json) =>
      _$MentionUserFromJson(json);

  @JsonKey(name: 'identity_number')
  String identityNumber;
  @JsonKey(name: 'full_name')
  String fullName;

  Map<String, dynamic> toJson() => _$MentionUserToJson(this);
}
