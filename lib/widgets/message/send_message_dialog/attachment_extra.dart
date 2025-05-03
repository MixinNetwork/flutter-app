import 'package:json_annotation/json_annotation.dart';

part 'attachment_extra.g.dart';

@JsonSerializable()
class AttachmentExtra {
  AttachmentExtra({
    required this.attachmentId,
    this.messageId,
    this.shareable,
    this.createdAt,
  });

  factory AttachmentExtra.fromJson(Map<String, dynamic> json) =>
      _$AttachmentExtraFromJson(json);

  @JsonKey(name: 'attachment_id')
  String attachmentId;
  @JsonKey(name: 'message_id')
  String? messageId;
  @JsonKey(name: 'created_at')
  String? createdAt;

  bool? shareable;

  Map<String, dynamic> toJson() => _$AttachmentExtraToJson(this);
}
