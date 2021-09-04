// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_minimal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TranscriptMinimal _$TranscriptMinimalFromJson(Map<String, dynamic> json) =>
    TranscriptMinimal(
      name: json['name'] as String,
      category: json['category'] as String,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$TranscriptMinimalToJson(TranscriptMinimal instance) =>
    <String, dynamic>{
      'name': instance.name,
      'category': instance.category,
      'content': instance.content,
    };
