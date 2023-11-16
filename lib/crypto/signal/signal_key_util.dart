import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart'
    hide generatePreKeys, generateSignedPreKey;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import 'identity_key_util.dart';
import 'pre_key_util.dart';
import 'signal_database.dart';
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
  return client.accountApi.pushSignalKeys(keys.toJson());
}

Future<SignalKeyRequest> generateKeys() async {
  final identityKeyPair = await getIdentityKeyPair(SignalDatabase.get);
  if (identityKeyPair == null) {
    throw InvalidKeyException('Local identity key pair is null!');
  }
  final oneTimePreKeys = await generatePreKeys();
  final signedPreKeyRecord = await generateSignedPreKey(identityKeyPair, false);
  return SignalKeyRequest.from(
      identityKeyPair.getPublicKey(), signedPreKeyRecord,
      preKeyRecords: oneTimePreKeys);
}
