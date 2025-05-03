import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'one_time_pre_key.g.dart';

@JsonSerializable()
class OneTimePreKey with EquatableMixin {
  OneTimePreKey(this.keyId, this.pubKey);

  factory OneTimePreKey.fromJson(Map<String, dynamic> json) =>
      _$OneTimePreKeyFromJson(json);

  @JsonKey(name: 'key_id')
  final int keyId;
  @JsonKey(name: 'pub_key')
  final String? pubKey;

  Map<String, dynamic> toJson() => _$OneTimePreKeyToJson(this);

  @override
  List<Object?> get props => [keyId, pubKey];
}
