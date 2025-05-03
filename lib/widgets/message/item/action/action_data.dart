import 'package:json_annotation/json_annotation.dart';

import '../../../../utils/uri_utils.dart';

part 'action_data.g.dart';

@JsonSerializable()
class ActionData {
  ActionData(this.label, this.color, this.action);

  factory ActionData.fromJson(Map<String, dynamic> json) =>
      _$ActionDataFromJson(json);

  String label;
  String color;
  String action;

  bool get isExternalLink {
    try {
      final uri = Uri.parse(action);
      return (uri.isScheme('http') || uri.isScheme('https')) &&
          !uri.isMixinActionUrl;
    } catch (error) {
      return false;
    }
  }

  bool get isSendUserLink {
    try {
      final uri = Uri.parse(action);
      return uri.isSendToUser;
    } catch (error) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => _$ActionDataToJson(this);
}
