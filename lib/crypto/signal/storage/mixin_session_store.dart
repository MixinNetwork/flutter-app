import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class MixinSessionStore extends SessionStore {
  @override
  bool containsSession(SignalProtocolAddress address) {
    // TODO: implement containsSession
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
  List<int> getSubDeviceSessions(String name) {
    // TODO: implement getSubDeviceSessions
    throw UnimplementedError();
  }

  @override
  SessionRecord loadSession(SignalProtocolAddress address) {
    // TODO: implement loadSession
    throw UnimplementedError();
  }

  @override
  void storeSession(SignalProtocolAddress address, SessionRecord record) {
    // TODO: implement storeSession
  }
}
