import 'package:json_annotation/json_annotation.dart';

import '../../../../utils/uri_utils.dart';
import '../action/action_data.dart';

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
    this.shareable,
    this.actions,
    this.coverUrl,
    this.cover,
  );

  factory AppCardData.fromJson(Map<String, dynamic> json) =>
      _$AppCardDataFromJson(json);

  @JsonKey(name: 'app_id')
  final String? appId;
  @JsonKey(name: 'icon_url')
  final String iconUrl;
  @JsonKey(name: 'cover_url', defaultValue: '')
  final String coverUrl;

  final Cover? cover;

  final String title;
  final String description;
  @JsonKey(name: 'action', defaultValue: '')
  final String action;
  @JsonKey(name: 'actions', defaultValue: [])
  final List<ActionData> actions;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @JsonKey(defaultValue: true)
  final bool shareable;

  Map<String, dynamic> toJson() => _$AppCardDataToJson(this);

  bool get isActionsCard => action.isEmpty;

  bool get canShareActions => actions.every((e) => e.isValidSharedAction);
}

@JsonSerializable()
class Cover {
  const Cover({
    required this.url,
    required this.thumbnail,
    required this.mimeType,
    required this.width,
    required this.height,
  });

  factory Cover.fromJson(Map<String, dynamic> json) => _$CoverFromJson(json);

  final String url;
  final String? thumbnail;
  @JsonKey(name: 'mime_type')
  final String mimeType;
  final int width;
  final int height;

  Map<String, dynamic> toJson() => _$CoverToJson(this);
}

extension on ActionData {
  bool get isValidSharedAction {
    try {
      final uri = Uri.parse(action);
      if (uri.isSendToUser) {
        return true;
      }
      if ((uri.isScheme('http') || uri.isScheme('https')) &&
          !uri.isHttpsSendUrl) {
        return true;
      }
    } catch (err) {
      return false;
    }
    return false;
  }
}
