import 'package:json_annotation/json_annotation.dart';

import '../../utils/json.dart';

part 'attachment_message.g.dart';

@JsonSerializable()
class AttachmentMessage {
  AttachmentMessage(
    this.key,
    this.digest,
    this.attachmentId,
    this.mimeType,
    this.size,
    this.name,
    this.width,
    this.height,
    this.thumbnail,
    this.duration,
    this.waveform,
    this.caption,
    this.createdAt,
  );

  factory AttachmentMessage.fromJson(Map<String, dynamic> json) =>
      _$AttachmentMessageFromJson(json);

  @JsonKey(
    name: 'key',
    toJson: dynamicToJson,
  )
  dynamic key;
  @JsonKey(
    name: 'digest',
    toJson: dynamicToJson,
  )
  dynamic digest;
  @JsonKey(name: 'attachment_id')
  String attachmentId;
  @JsonKey(name: 'mime_type')
  String mimeType;
  @JsonKey(name: 'size')
  int size;
  @JsonKey(name: 'name')
  String? name;
  @JsonKey(name: 'width')
  int? width;
  @JsonKey(name: 'height')
  int? height;
  @JsonKey(name: 'thumbnail')
  String? thumbnail;
  @JsonKey(name: 'duration')
  int? duration;
  @JsonKey(
    name: 'waveform',
    toJson: dynamicToJson,
  )
  dynamic waveform;
  @JsonKey(name: 'caption')
  String? caption;
  @JsonKey(name: 'created_at')
  String? createdAt;

  Map<String, dynamic> toJson() => _$AttachmentMessageToJson(this);
}
