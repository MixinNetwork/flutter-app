import 'package:json_annotation/json_annotation.dart';

part 'live_message.g.dart';

@JsonSerializable()
class LiveMessage {
  LiveMessage(
      this.width, this.height, this.thumbUrl,this.url);

  factory LiveMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveMessageFromJson(json);

  @JsonKey(name: 'width', disallowNullValue: true)
  int width;
  @JsonKey(name: 'height', disallowNullValue: true)
  int height;
  @JsonKey(name: 'thumb_url', disallowNullValue: true)
  String thumbUrl;
  @JsonKey(name: 'url', disallowNullValue: true)
  String url;

  Map<String, dynamic> toJson() => _$LiveMessageToJson(this);
}

