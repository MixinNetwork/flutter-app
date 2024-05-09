// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Inscription _$InscriptionFromJson(Map<String, dynamic> json) => Inscription(
      collectionHash: json['collection_hash'] as String,
      inscriptionHash: json['inscription_hash'] as String,
      sequence: (json['sequence'] as num).toInt(),
      contentType: json['content_type'] as String,
      contentUrl: json['content_url'] as String,
      name: json['name'] as String?,
      iconUrl: json['icon_url'] as String?,
    );

Map<String, dynamic> _$InscriptionToJson(Inscription instance) =>
    <String, dynamic>{
      'collection_hash': instance.collectionHash,
      'inscription_hash': instance.inscriptionHash,
      'name': instance.name,
      'sequence': instance.sequence,
      'content_type': instance.contentType,
      'content_url': instance.contentUrl,
      'icon_url': instance.iconUrl,
    };
