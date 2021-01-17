import 'package:json_annotation/json_annotation.dart';

part 'live_message.g.dart';

@JsonSerializable()
class LiveMessage {
  LiveMessage(
      this.width, this.height, this.thumbUrl,this.url);

  factory LiveMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveMessageFromJson(json);

  @JsonKey(name: 'width', nullable: false)
  int width;
  @JsonKey(name: 'height', nullable: false)
  int height;
  @JsonKey(name: 'thumb_url', nullable: false)
  String thumbUrl;
  @JsonKey(name: 'url', nullable: false)
  String url;

  Map<String, dynamic> toJson() => _$LiveMessageToJson(this);
}

