import 'package:flutter_app/crypto/signal/vo/Session.dart';
import 'package:flutter_app/objectbox.g.dart';

class SessionDao {
  SessionDao(Store store) {
    sessionBox = store.box<Session>();
  }

  late Box<Session> sessionBox;

  Session? getSession(String address, int deviceId) {
    final query = sessionBox
        .query(Session_.address
            .equals(address)
            .and(Session_.device.equals(deviceId)))
        .build();
    final session = query.findFirst();
    query.close();
    return session;
  }

  List<int> getSubDevice(String address) {
    final query = sessionBox
        .query(
            Session_.address.equals(address).and(Session_.device.notEquals(1)))
        .build();
    final devices = query.integerProperty(Session_.device).find();
    query.close();
    return devices;
  }

  List<Session> getSessions(String address) {
    final query = sessionBox.query(Session_.address.equals(address)).build();
    final sessions = query.find();
    query.close();
    return sessions;
  }

  int deleteSessions(String address) {
    final query = sessionBox.query(Session_.address.equals(address)).build();
    final count = query.remove();
    query.close();
    return count;
  }

  List<Session> getSessionAddress() {
    final query = sessionBox.query(Session_.device.equals(1)).build();
    final sessions = query.find();
    query.close();
    return sessions;
  }
}
