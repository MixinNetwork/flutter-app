import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../blaze/vo/one_time_pre_key.dart';
import '../../blaze/vo/signed_pre_key.dart';

part 'signal_key_request.g.dart';

@JsonSerializable()
class SignalKeyRequest with EquatableMixin {
  SignalKeyRequest(this.identityKey, this.signedPreKey, this.oneTimePreKeys);

  SignalKeyRequest.from(IdentityKey ik, SignedPreKeyRecord spk,
      {List<PreKeyRecord>? preKeyRecords}) {
    identityKey = base64.encode(ik.serialize());
    final publicBase64 = base64.encode(spk.getKeyPair().publicKey.serialize());
    final signatureBase64 = base64.encode(spk.signature);
    signedPreKey = SignedPreKey(spk.id, publicBase64, signatureBase64);
    if (preKeyRecords != null) {
      oneTimePreKeys = <OneTimePreKey>[];
      preKeyRecords.forEach((e) => oneTimePreKeys.add(OneTimePreKey(
          e.id, base64.encode(e.getKeyPair().publicKey.serialize()))));
    }
  }

  factory SignalKeyRequest.fromJson(Map<String, dynamic> json) =>
      _$SignalKeyRequestFromJson(json);

  @JsonKey(name: 'identity_key')
  late String identityKey;
  @JsonKey(name: 'signed_pre_key')
  late SignedPreKey signedPreKey;
  @JsonKey(name: 'one_time_pre_keys')
  late List<OneTimePreKey> oneTimePreKeys;

  Map<String, dynamic> toJson() => _$SignalKeyRequestToJson(this);

  @override
  List<Object?> get props => [
        identityKey,
        signedPreKey,
        oneTimePreKeys,
      ];
}
