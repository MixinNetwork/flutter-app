import 'package:json_annotation/json_annotation.dart';

part 'app_card.g.dart';

@JsonSerializable()
class AppCard {
  AppCard(this.appId, this.iconUrl, this.title, this.description, this.action,
      this.updatedAt);

  factory AppCard.fromJson(Map<String, dynamic> json) =>
      _$AppCardFromJson(json);

  @JsonKey(name: 'app_id')
  String appId;
  @JsonKey(name: 'icon_url', disallowNullValue: false)
  String iconUrl;
  @JsonKey(name: 'title', disallowNullValue: false)
  String title;
  @JsonKey(name: 'description', disallowNullValue: false)
  String description;
  @JsonKey(name: 'action', disallowNullValue: false)
  String action;
  @JsonKey(name: 'updatedAt')
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$AppCardToJson(this);
}
