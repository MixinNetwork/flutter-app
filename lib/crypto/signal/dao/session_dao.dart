import 'package:drift/drift.dart';

import '../signal_database.dart';

part 'session_dao.g.dart';

@DriftAccessor()
class SessionDao extends DatabaseAccessor<SignalDatabase>
    with _$SessionDaoMixin {
  SessionDao(super.db);

  Future<Session?> getSession(String address, int deviceId) =>
      (select(db.sessions)
            ..where(
              (tbl) =>
                  tbl.address.equals(address) & tbl.device.equals(deviceId),
            )
            ..limit(1))
          .getSingleOrNull();

  Future<List<int>> getSubDevice(String address) async {
    final list =
        await (selectOnly(db.sessions)
              ..addColumns([db.sessions.device])
              ..where(
                db.sessions.address.equals(address) &
                    db.sessions.device.equals(1).not(),
              ))
            .map((row) => row.read(db.sessions.device))
            .get();
    return list.nonNulls.toList();
  }

  Future<List<Session>> getSessions(String address) async =>
      (select(db.sessions)..where((tbl) => tbl.address.equals(address))).get();

  Future<int> deleteSessionsByAddress(String address) =>
      (delete(db.sessions)..where((tbl) => tbl.address.equals(address))).go();

  Future<List<Session>> getSessionAddress() async =>
      (select(db.sessions)..where((tbl) => tbl.device.equals(1))).get();

  Future deleteSession(Session session) => delete(db.sessions).delete(session);

  Future insertSession(SessionsCompanion session) async =>
      into(db.sessions).insert(session, mode: InsertMode.insertOrReplace);

  Future insertList(List<SessionsCompanion> list) async => batch(
    (batch) =>
        batch.insertAll(db.sessions, list, mode: InsertMode.insertOrReplace),
  );
}
