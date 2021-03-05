import 'package:json_annotation/json_annotation.dart';

part 'action_card_data.g.dart';

@JsonSerializable()
class AppCardData {
  const AppCardData(
    this.appId,
    this.iconUrl,
    this.title,
    this.description,
    this.action,
    this.updatedAt,
  );

  factory AppCardData.fromJson(Map<String, dynamic> json) =>
      _$AppCardDataFromJson(json);

  @JsonKey(name: 'app_id')
  final String? appId;
  @JsonKey(name: 'icon_url')
  final String iconUrl;
  final String title;
  final String description;
  final String action;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  Map<String, dynamic> toJson() => _$AppCardDataToJson(this);
}
