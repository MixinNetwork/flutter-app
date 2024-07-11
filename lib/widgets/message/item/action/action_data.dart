import 'package:json_annotation/json_annotation.dart';

part 'action_data.g.dart';

@JsonSerializable()
class ActionData {
  ActionData(
    this.label,
    this.color,
    this.action,
  );

  factory ActionData.fromJson(Map<String, dynamic> json) =>
      _$ActionDataFromJson(json);

  String label;
  String color;
  String action;

  bool get isExternalLink {
    if (action.startsWith('input:')) {
      return false;
    }
    try {
      final uri = Uri.parse(action);
      if (uri.scheme == 'mixin') {
        return false;
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => _$ActionDataToJson(this);
}
