import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'one_time_pre_key.dart';

part 'signed_pre_key.g.dart';

@JsonSerializable()
class SignedPreKey extends OneTimePreKey with EquatableMixin {
  SignedPreKey(super.keyId, super.pubKey, this.signature);

  factory SignedPreKey.fromJson(Map<String, dynamic> json) =>
      _$SignedPreKeyFromJson(json);

  @JsonKey(name: 'signature')
  final String signature;

  @override
  Map<String, dynamic> toJson() => _$SignedPreKeyToJson(this);

  @override
  List<Object?> get props => [keyId, pubKey, signature];
}
