import 'package:json_annotation/json_annotation.dart';

part 'app_button.g.dart';

@JsonSerializable()
class AppButton {
  AppButton(this.label, this.color, this.action);

  factory AppButton.fromJson(Map<String, dynamic> json) =>
      _$AppButtonFromJson(json);

  @JsonKey(name: 'label', disallowNullValue: false)
  String label;
  @JsonKey(name: 'color')
  String color;
  @JsonKey(name: 'action')
  String action;

  Map<String, dynamic> toJson() => _$AppButtonToJson(this);
}
