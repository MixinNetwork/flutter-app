import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/signal/dao/session_dao.dart';
import 'package:flutter_app/crypto/signal/signal_protocol.dart';
import 'package:flutter_app/crypto/signal/vo/Session.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:objectbox/objectbox.dart';

class MixinSessionStore extends SessionStore {
  MixinSessionStore(Store store) {
    sessionDao = SessionDao(store);
  }

  late SessionDao sessionDao;

  @override
  bool containsSession(SignalProtocolAddress address) {
    final session =
        sessionDao.getSession(address.getName(), address.getDeviceId());
    if (session == null) {
      return false;
    }
    final sessionRecord = loadSession(address);
    return sessionRecord.sessionState.hasSenderChain() &&
        sessionRecord.sessionState.getSessionVersion() ==
            CiphertextMessage.CURRENT_VERSION;
  }

  @override
  void deleteAllSessions(String name) {
    final devices = getSubDeviceSessions(name);
    deleteSession(SignalProtocolAddress(name, SignalProtocol.defaultDeviceId));
    for (final device in devices) {
      deleteSession(SignalProtocolAddress(name, device));
    }
  }

  @override
  void deleteSession(SignalProtocolAddress address) {
    final session =
        sessionDao.getSession(address.getName(), address.getDeviceId());
    if (session != null) {
      sessionDao.delete(session);
    }
  }

  @override
  List<int> getSubDeviceSessions(String name) {
    return sessionDao.getSubDevice(name);
  }

  @override
  SessionRecord loadSession(SignalProtocolAddress address) {
    final session =
        sessionDao.getSession(address.getName(), address.getDeviceId());
    if (session != null) {
      return SessionRecord.fromSerialized(session.record);
    }
    return SessionRecord();
  }

  @override
  void storeSession(SignalProtocolAddress address, SessionRecord record) {
    final session =
        sessionDao.getSession(address.getName(), address.getDeviceId());
    if ((session == null) || !listEquals(session.record, record.serialize())) {
      sessionDao.insert(Session(address.getName(), address.getDeviceId(),
          record.serialize(), DateTime.now()));
    }
  }
}
