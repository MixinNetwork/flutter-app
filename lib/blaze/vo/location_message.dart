import 'package:json_annotation/json_annotation.dart';

part 'location_message.g.dart';

@JsonSerializable()
class LocationMessage {
  LocationMessage(
      this.latitude, this.longitude, this.name, this.address, this.venueType);

  factory LocationMessage.fromJson(Map<String, dynamic> json) =>
      _$LocationMessageFromJson(json);

  @JsonKey(name: 'latitude')
  double latitude;
  @JsonKey(name: 'longitude')
  double longitude;
  @JsonKey(name: 'name')
  String name;
  @JsonKey(name: 'address')
  String address;
  @JsonKey(name: 'venue_type')
  String venueType;

  Map<String, dynamic> toJson() => _$LocationMessageToJson(this);
}
