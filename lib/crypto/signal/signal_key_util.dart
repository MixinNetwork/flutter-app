import 'package:flutter_app/crypto/signal/pre_key_util.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import 'signal_key_request.dart';

Future checkSignalKey(Client client) async {
  final response = await client.accountApi.getSignalKeyCount();
  final availableKeyCount = response.data.preKeyCount;
  if (availableKeyCount > 500) {
    return;
  }
  await refreshSignalKeys(client);
}

Future<MixinResponse<void>> refreshSignalKeys(Client client) async {
  final keys = generateKeys();
  return await client.accountApi.pushSignalKeys(keys.toString());
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
