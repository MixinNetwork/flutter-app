import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class MixinSignalProtocolStore extends SignalProtocolStore {
  @override
  bool containsPreKey(int preKeyId) {
    // TODO: implement containsPreKey
    throw UnimplementedError();
  }

  @override
  bool containsSession(SignalProtocolAddress address) {
    // TODO: implement containsSession
    throw UnimplementedError();
  }

  @override
  bool containsSignedPreKey(int signedPreKeyId) {
    // TODO: implement containsSignedPreKey
    throw UnimplementedError();
  }

  @override
  void deleteAllSessions(String name) {
    // TODO: implement deleteAllSessions
  }

  @override
  void deleteSession(SignalProtocolAddress address) {
    // TODO: implement deleteSession
  }

  @override
  IdentityKey getIdentity(SignalProtocolAddress address) {
    // TODO: implement getIdentity
    throw UnimplementedError();
  }

  @override
  IdentityKeyPair getIdentityKeyPair() {
    // TODO: implement getIdentityKeyPair
    throw UnimplementedError();
  }

  @override
  int getLocalRegistrationId() {
    // TODO: implement getLocalRegistrationId
    throw UnimplementedError();
  }

  @override
  List<int> getSubDeviceSessions(String name) {
    // TODO: implement getSubDeviceSessions
    throw UnimplementedError();
  }

  @override
  PreKeyRecord loadPreKey(int preKeyId) {
    // TODO: implement loadPreKey
    throw UnimplementedError();
  }

  @override
  SessionRecord loadSession(SignalProtocolAddress address) {
    // TODO: implement loadSession
    throw UnimplementedError();
  }

  @override
  SignedPreKeyRecord loadSignedPreKey(int signedPreKeyId) {
    // TODO: implement loadSignedPreKey
    throw UnimplementedError();
  }

  @override
  List<SignedPreKeyRecord> loadSignedPreKeys() {
    // TODO: implement loadSignedPreKeys
    throw UnimplementedError();
  }

  @override
  void removePreKey(int preKeyId) {
    // TODO: implement removePreKey
  }

  @override
  void removeSignedPreKey(int signedPreKeyId) {
    // TODO: implement removeSignedPreKey
  }

  @override
  void storePreKey(int preKeyId, PreKeyRecord record) {
    // TODO: implement storePreKey
  }

  @override
  void storeSession(SignalProtocolAddress address, SessionRecord record) {
    // TODO: implement storeSession
  }

  @override
  void storeSignedPreKey(int signedPreKeyId, SignedPreKeyRecord record) {
    // TODO: implement storeSignedPreKey
  }

  @override
  bool isTrustedIdentity(SignalProtocolAddress address,
      IdentityKey? identityKey, Direction direction) {
    // TODO: implement isTrustedIdentity
    throw UnimplementedError();
  }

  @override
  bool saveIdentity(SignalProtocolAddress address, IdentityKey? identityKey) {
    // TODO: implement saveIdentity
    throw UnimplementedError();
  }
}
