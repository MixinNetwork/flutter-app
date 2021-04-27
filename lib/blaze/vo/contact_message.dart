import 'package:json_annotation/json_annotation.dart';

part 'contact_message.g.dart';

@JsonSerializable()
class ContactMessage {
  ContactMessage(
    this.userId,
  );

  factory ContactMessage.fromJson(Map<String, dynamic> json) =>
      _$ContactMessageFromJson(json);

  @JsonKey(name: 'user_id')
  String userId;

  Map<String, dynamic> toJson() => _$ContactMessageToJson(this);
}
