import 'package:moor/moor.dart';

import '../signal_database.dart';

part 'session_dao.g.dart';

@UseDao(tables: [Sessions])
class SessionDao extends DatabaseAccessor<SignalDatabase>
    with _$SessionDaoMixin {
  SessionDao(SignalDatabase db) : super(db);

  Future<Session?> getSession(String address, int deviceId) async => db
      .customSelect('SELECT * FROM sessions WHERE address = ? AND device = ?',
          variables: [Variable.withString(address), Variable.withInt(deviceId)])
      .map((row) => Session(
            id: row.readInt('id'),
            address: row.readString('address'),
            device: row.readInt('device'),
            record: row.readBlob('record'),
            timestamp: row.readInt('timestamp'),
          ))
      .getSingleOrNull();

  Future<List<int>> getSubDevice(String address) async => db
      .customSelect('SELECT * FROM sessions WHERE address = ? AND device != 1',
          variables: [
            Variable.withString(address),
          ])
      .map((row) => row.readInt('device'))
      .get();

  Future<List<Session>> getSessions(String address) async =>
      (select(db.sessions)..where((tbl) => tbl.address.equals(address))).get();

  Future<int> deleteSessionsByAddress(String address) =>
      (delete(db.sessions)..where((tbl) => tbl.address.equals(address))).go();

  Future<List<Session>> getSessionAddress() async => select(db.sessions).get();

  Future deleteSession(Session session) => delete(db.sessions).delete(session);

  Future insert(Session session) => into(db.sessions).insert(session);
}
