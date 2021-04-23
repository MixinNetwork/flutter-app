import 'package:json_annotation/json_annotation.dart';

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
      this.caption);

  factory AttachmentMessage.fromJson(Map<String, dynamic> json) =>
      _$AttachmentMessageFromJson(json);

  @JsonKey(name: 'key')
  dynamic key;
  @JsonKey(name: 'digest')
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
  @JsonKey(name: 'waveform')
  dynamic waveform;
  @JsonKey(name: 'caption')
  String? caption;

  Map<String, dynamic> toJson() => _$AttachmentMessageToJson(this);
}
