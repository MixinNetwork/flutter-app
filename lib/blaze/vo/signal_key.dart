import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../utils/extension/extension.dart';
import 'one_time_pre_key.dart';
import 'signed_pre_key.dart';

part 'signal_key.g.dart';

@JsonSerializable()
class SignalKey {
  SignalKey(
    this.identityKey,
    this.signedPreKey,
    this.preKey,
    this.registrationId,
    this.userId,
    this.sessionId,
  );

  factory SignalKey.fromJson(Map<String, dynamic> json) =>
      _$SignalKeyFromJson(json);

  @JsonKey(name: 'identity_key')
  String identityKey;
  @JsonKey(name: 'signed_pre_key')
  SignedPreKey signedPreKey;
  @JsonKey(name: 'one_time_pre_key')
  OneTimePreKey preKey;
  @JsonKey(name: 'registration_id')
  int registrationId;
  @JsonKey(name: 'user_id')
  String userId;
  @JsonKey(name: 'session_id')
  String sessionId;

  Map<String, dynamic> toJson() => _$SignalKeyToJson(this);

  PreKeyBundle createPreKeyBundle() => PreKeyBundle(
    registrationId,
    sessionId.getDeviceId(),
    preKey.keyId,
    getPreKeyPublic(),
    signedPreKey.keyId,
    getSignedPreKeyPublic(),
    getSignedSignature(),
    getIdentity(),
  );

  ECPublicKey? getPreKeyPublic() => getPublicKey(preKey.pubKey);

  ECPublicKey? getSignedPreKeyPublic() => getPublicKey(signedPreKey.pubKey);

  ECPublicKey? getPublicKey(String? pub) {
    if (pub != null && pub.isEmpty) {
      return null;
    }
    try {
      return Curve.decodePoint(base64.decode(pub!), 0);
    } on InvalidKeyException {
      return null;
    } on IOException {
      return null;
    }
  }

  Uint8List getSignedSignature() => base64.decode(signedPreKey.signature);

  IdentityKey getIdentity() =>
      IdentityKey.fromBytes(base64.decode(identityKey), 0);
}
