// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_card_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppCardData _$AppCardDataFromJson(Map<String, dynamic> json) => AppCardData(
      json['app_id'] as String?,
      json['icon_url'] as String,
      json['title'] as String,
      json['description'] as String,
      json['action'] as String,
      json['updated_at'] as String,
      json['shareable'] as bool? ?? true,
    );

Map<String, dynamic> _$AppCardDataToJson(AppCardData instance) =>
    <String, dynamic>{
      'app_id': instance.appId,
      'icon_url': instance.iconUrl,
      'title': instance.title,
      'description': instance.description,
      'action': instance.action,
      'updated_at': instance.updatedAt,
      'shareable': instance.shareable,
    };
