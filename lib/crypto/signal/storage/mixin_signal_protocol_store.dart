import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'mixin_identity_key_store.dart';
import 'mixin_session_store.dart';

class MixinSignalProtocolStore extends SignalProtocolStore {
  MixinSignalProtocolStore(
    this.preKeyStore,
    this.signedPreKeyStore,
    this.identityKeyStore,
    this.sessionStore,
  );

  final PreKeyStore preKeyStore;
  final SignedPreKeyStore signedPreKeyStore;
  final MixinIdentityKeyStore identityKeyStore;
  final MixinSessionStore sessionStore;

  @override
  Future<bool> containsPreKey(int preKeyId) async =>
      preKeyStore.containsPreKey(preKeyId);

  @override
  Future<bool> containsSession(SignalProtocolAddress address) async =>
      sessionStore.containsSession(address);

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async =>
      signedPreKeyStore.containsSignedPreKey(signedPreKeyId);

  @override
  Future deleteAllSessions(String name) async {
    await sessionStore.deleteAllSessions(name);
  }

  @override
  Future deleteSession(SignalProtocolAddress address) async {
    await sessionStore.deleteSession(address);
  }

  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async =>
      identityKeyStore.getIdentity(address);

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async =>
      identityKeyStore.getIdentityKeyPair();

  @override
  Future<int> getLocalRegistrationId() async =>
      identityKeyStore.getLocalRegistrationId();

  @override
  Future<List<int>> getSubDeviceSessions(String name) async =>
      sessionStore.getSubDeviceSessions(name);

  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async =>
      preKeyStore.loadPreKey(preKeyId);

  @override
  Future<SessionRecord> loadSession(SignalProtocolAddress address) async =>
      sessionStore.loadSession(address);

  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async =>
      signedPreKeyStore.loadSignedPreKey(signedPreKeyId);

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async =>
      signedPreKeyStore.loadSignedPreKeys();

  @override
  Future<void> removePreKey(int preKeyId) async {
    await preKeyStore.removePreKey(preKeyId);
  }

  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
    await signedPreKeyStore.removeSignedPreKey(signedPreKeyId);
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    await preKeyStore.storePreKey(preKeyId, record);
  }

  @override
  Future storeSession(
    SignalProtocolAddress address,
    SessionRecord record,
  ) async {
    await sessionStore.storeSession(address, record);
  }

  @override
  Future<void> storeSignedPreKey(
    int signedPreKeyId,
    SignedPreKeyRecord record,
  ) async {
    await signedPreKeyStore.storeSignedPreKey(signedPreKeyId, record);
  }

  @override
  Future<bool> isTrustedIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
    Direction direction,
  ) async =>
      identityKeyStore.isTrustedIdentity(address, identityKey, direction);

  @override
  Future<bool> saveIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
  ) async => identityKeyStore.saveIdentity(address, identityKey);

  Future<void> removeIdentity(SignalProtocolAddress address) async {
    await identityKeyStore.removeIdentity(address);
  }
}
