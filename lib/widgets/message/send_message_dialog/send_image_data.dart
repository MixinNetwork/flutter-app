import 'package:json_annotation/json_annotation.dart';

import 'attachment_extra.dart';

part 'send_image_data.g.dart';

@JsonSerializable()
class SendImageData {
  SendImageData({required this.url, this.attachmentExtra});

  factory SendImageData.fromJson(Map<String, dynamic> json) =>
      _$SendImageDataFromJson(json);

  @JsonKey(name: 'url')
  String url;
  @JsonKey(name: 'attachment_extra')
  AttachmentExtra? attachmentExtra;

  Map<String, dynamic> toJson() => _$SendImageDataToJson(this);
}
