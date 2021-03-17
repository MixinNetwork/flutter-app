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
  @JsonKey(name: 'icon_url')
  String iconUrl;
  @JsonKey(name: 'title')
  String title;
  @JsonKey(name: 'description')
  String description;
  @JsonKey(name: 'action')
  String action;
  @JsonKey(name: 'updatedAt')
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$AppCardToJson(this);
}
