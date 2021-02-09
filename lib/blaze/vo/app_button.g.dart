// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_button.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppButton _$AppButtonFromJson(Map<String, dynamic> json) {
  return AppButton(
    json['label'] as String,
    json['color'] as String,
    json['action'] as String,
  );
}

Map<String, dynamic> _$AppButtonToJson(AppButton instance) => <String, dynamic>{
      'label': instance.label,
      'color': instance.color,
      'action': instance.action,
    };
