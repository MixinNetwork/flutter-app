// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataApp _$TransferDataAppFromJson(Map<String, dynamic> json) =>
    TransferDataApp(
      appId: json['app_id'] as String,
      appNumber: json['app_number'] as String,
      homeUri: json['home_uri'] as String,
      redirectUri: json['redirect_uri'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String,
      category: json['category'] as String?,
      description: json['description'] as String,
      appSecret: json['app_secret'] as String,
      capabilities: (json['capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      creatorId: json['creator_id'] as String,
      resourcePatterns: (json['resource_patterns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TransferDataAppToJson(TransferDataApp instance) =>
    <String, dynamic>{
      'app_id': instance.appId,
      'app_number': instance.appNumber,
      'home_uri': instance.homeUri,
      'redirect_uri': instance.redirectUri,
      'name': instance.name,
      'icon_url': instance.iconUrl,
      'category': instance.category,
      'description': instance.description,
      'app_secret': instance.appSecret,
      'capabilities': instance.capabilities,
      'creator_id': instance.creatorId,
      'resource_patterns': instance.resourcePatterns,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
