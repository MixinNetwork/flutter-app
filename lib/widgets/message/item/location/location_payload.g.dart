// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationPayload _$LocationPayloadFromJson(Map<String, dynamic> json) =>
    LocationPayload(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name'] as String?,
      address: json['address'] as String?,
      venueType: json['venue_type'] as String?,
    );

Map<String, dynamic> _$LocationPayloadToJson(LocationPayload instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'name': instance.name,
      'address': instance.address,
      'venue_type': instance.venueType,
    };
