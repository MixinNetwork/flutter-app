import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class MixinSignalProtocolStore extends SignalProtocolStore {
  MixinSignalProtocolStore(this.preKeyStore, this.signedPreKeyStore,
      this.identityKeyStore, this.sessionStore);

  final PreKeyStore preKeyStore;
  final SignedPreKeyStore signedPreKeyStore;
  final IdentityKeyStore identityKeyStore;
  final SessionStore sessionStore;

  @override
  bool containsPreKey(int preKeyId) {
    return preKeyStore.containsPreKey(preKeyId);
  }

  @override
  bool containsSession(SignalProtocolAddress address) {
    return sessionStore.containsSession(address);
  }

  @override
  bool containsSignedPreKey(int signedPreKeyId) {
    return signedPreKeyStore.containsSignedPreKey(signedPreKeyId);
  }

  @override
  void deleteAllSessions(String name) {
    sessionStore.deleteAllSessions(name);
  }

  @override
  void deleteSession(SignalProtocolAddress address) {
    sessionStore.deleteSession(address);
  }

  @override
  IdentityKey getIdentity(SignalProtocolAddress address) {
    return identityKeyStore.getIdentity(address);
  }

  @override
  IdentityKeyPair getIdentityKeyPair() {
    return identityKeyStore.getIdentityKeyPair();
  }

  @override
  int getLocalRegistrationId() {
    return identityKeyStore.getLocalRegistrationId();
  }

  @override
  List<int> getSubDeviceSessions(String name) {
    return sessionStore.getSubDeviceSessions(name);
  }

  @override
  PreKeyRecord loadPreKey(int preKeyId) {
    return preKeyStore.loadPreKey(preKeyId);
  }

  @override
  SessionRecord loadSession(SignalProtocolAddress address) {
    return sessionStore.loadSession(address);
  }

  @override
  SignedPreKeyRecord loadSignedPreKey(int signedPreKeyId) {
    return signedPreKeyStore.loadSignedPreKey(signedPreKeyId);
  }

  @override
  List<SignedPreKeyRecord> loadSignedPreKeys() {
    return signedPreKeyStore.loadSignedPreKeys();
  }

  @override
  void removePreKey(int preKeyId) {
    preKeyStore.removePreKey(preKeyId);
  }

  @override
  void removeSignedPreKey(int signedPreKeyId) {
    signedPreKeyStore.removeSignedPreKey(signedPreKeyId);
  }

  @override
  void storePreKey(int preKeyId, PreKeyRecord record) {
    preKeyStore.storePreKey(preKeyId, record);
  }

  @override
  void storeSession(SignalProtocolAddress address, SessionRecord record) {
    sessionStore.storeSession(address, record);
  }

  @override
  void storeSignedPreKey(int signedPreKeyId, SignedPreKeyRecord record) {
    signedPreKeyStore.storeSignedPreKey(signedPreKeyId, record);
  }

  @override
  bool isTrustedIdentity(SignalProtocolAddress address,
      IdentityKey? identityKey, Direction direction) {
    return identityKeyStore.isTrustedIdentity(address, identityKey, direction);
  }

  @override
  bool saveIdentity(SignalProtocolAddress address, IdentityKey? identityKey) {
    return identityKeyStore.saveIdentity(address, identityKey);
  }
}
