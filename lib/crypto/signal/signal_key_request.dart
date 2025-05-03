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

  factory SignalKeyRequest.from(
    IdentityKey ik,
    SignedPreKeyRecord spk, {
    List<PreKeyRecord>? preKeyRecords,
  }) {
    final identityKey = base64.encode(ik.serialize());
    final publicBase64 = base64.encode(spk.getKeyPair().publicKey.serialize());
    final signatureBase64 = base64.encode(spk.signature);
    final signedPreKey = SignedPreKey(spk.id, publicBase64, signatureBase64);
    final oneTimePreKeys = <OneTimePreKey>[];
    if (preKeyRecords != null) {
      preKeyRecords.forEach(
        (e) => oneTimePreKeys.add(
          OneTimePreKey(
            e.id,
            base64.encode(e.getKeyPair().publicKey.serialize()),
          ),
        ),
      );
    }
    return SignalKeyRequest(identityKey, signedPreKey, oneTimePreKeys);
  }

  factory SignalKeyRequest.fromJson(Map<String, dynamic> json) =>
      _$SignalKeyRequestFromJson(json);

  @JsonKey(name: 'identity_key')
  final String identityKey;
  @JsonKey(name: 'signed_pre_key')
  final SignedPreKey signedPreKey;
  @JsonKey(name: 'one_time_pre_keys')
  final List<OneTimePreKey> oneTimePreKeys;

  Map<String, dynamic> toJson() => _$SignalKeyRequestToJson(this);

  @override
  List<Object?> get props => [identityKey, signedPreKey, oneTimePreKeys];
}
