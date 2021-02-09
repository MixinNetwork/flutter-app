import 'package:json_annotation/json_annotation.dart';

part 'app_button.g.dart';

@JsonSerializable()
class AppButton {
  AppButton(this.label, this.color, this.action);

  factory AppButton.fromJson(Map<String, dynamic> json) =>
      _$AppButtonFromJson(json);

  @JsonKey(name: 'label',nullable: true)
  String label;
  @JsonKey(name: 'color', nullable: true)
  String color;
  @JsonKey(name: 'action', nullable: true)
  String action;

  Map<String, dynamic> toJson() => _$AppButtonToJson(this);
}
