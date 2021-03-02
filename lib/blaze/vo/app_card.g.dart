// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppCard _$AppCardFromJson(Map<String, dynamic> json) {
  return AppCard(
    json['app_id'] as String,
    json['icon_url'] as String,
    json['title'] as String,
    json['description'] as String,
    json['action'] as String,
    json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$AppCardToJson(AppCard instance) => <String, dynamic>{
      'app_id': instance.appId,
      'icon_url': instance.iconUrl,
      'title': instance.title,
      'description': instance.description,
      'action': instance.action,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
