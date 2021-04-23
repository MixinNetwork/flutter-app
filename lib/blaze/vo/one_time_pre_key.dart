import 'package:json_annotation/json_annotation.dart';

part 'one_time_pre_key.g.dart';

@JsonSerializable()
class OneTimePreKey {
  OneTimePreKey(this.keyId, this.pubKey);

  factory OneTimePreKey.fromJson(Map<String, dynamic> json) =>
      _$OneTimePreKeyFromJson(json);

  @JsonKey(name: 'key_id')
  int keyId;
  @JsonKey(name: 'pub_key')
  String? pubKey;

  Map<String, dynamic> toJson() => _$OneTimePreKeyToJson(this);
}
