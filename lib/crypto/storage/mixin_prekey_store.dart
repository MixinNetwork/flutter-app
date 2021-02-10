import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class MixinPreKeyStore extends PreKeyStore {
  @override
  bool containsPreKey(int preKeyId) {
    // TODO: implement containsPreKey
    throw UnimplementedError();
  }

  @override
  PreKeyRecord loadPreKey(int preKeyId) {
    // TODO: implement loadPreKey
    throw UnimplementedError();
  }

  @override
  void removePreKey(int preKeyId) {
    // TODO: implement removePreKey
  }

  @override
  void storePreKey(int preKeyId, PreKeyRecord record) {
    // TODO: implement storePreKey
  }
}
