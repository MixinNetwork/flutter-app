// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationMessage _$LocationMessageFromJson(Map<String, dynamic> json) {
  return LocationMessage(
    (json['latitude'] as num).toDouble(),
    (json['longitude'] as num).toDouble(),
    json['name'] as String,
    json['address'] as String,
    json['venue_type'] as String,
  );
}

Map<String, dynamic> _$LocationMessageToJson(LocationMessage instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'name': instance.name,
      'address': instance.address,
      'venue_type': instance.venueType,
    };
