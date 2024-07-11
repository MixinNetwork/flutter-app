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

  bool get isExternalLink =>
      action.startsWith('https://') || action.startsWith('http://');

  Map<String, dynamic> toJson() => _$ActionDataToJson(this);
}
