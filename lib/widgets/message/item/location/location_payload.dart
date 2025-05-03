import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_payload.g.dart';

@JsonSerializable()
class LocationPayload with EquatableMixin {
  LocationPayload({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    this.venueType,
  });

  factory LocationPayload.fromJson(Map<String, dynamic> json) =>
      _$LocationPayloadFromJson(json);

  final double latitude;
  final double longitude;
  final String? name;
  final String? address;
  @JsonKey(name: 'venue_type')
  final String? venueType;

  Map<String, dynamic> toJson() => _$LocationPayloadToJson(this);

  @override
  List<Object?> get props => [latitude, longitude, name, address, venueType];
}
