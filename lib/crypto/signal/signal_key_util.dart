import 'dart:convert';

import 'package:flutter_app/crypto/signal/pre_key_util.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import 'signal_key_request.dart';

const int preKeyMinNum = 500;

Future checkSignalKey(Client client) async {
  final response = await client.accountApi.getSignalKeyCount();
  final availableKeyCount = response.data.preKeyCount;
  if (availableKeyCount > preKeyMinNum) {
    return;
  }
  await refreshSignalKeys(client);
}

Future<MixinResponse<void>> refreshSignalKeys(Client client) async {
  final keys = await generateKeys();
  return client.accountApi.pushSignalKeys(json.encode(keys.toJson()));
}

Future<SignalKeyRequest> generateKeys() async {
  final identityKeyPair = KeyHelper.generateIdentityKeyPair();
  final oneTimePreKeys = await PreKeyUtil.generatePreKeys();
  final signedPreKeyRecord =
      await PreKeyUtil.generateSignedPreKey(identityKeyPair, false);
  return SignalKeyRequest.from(
      identityKeyPair.getPublicKey(), signedPreKeyRecord,
      preKeyRecords: oneTimePreKeys);
}
