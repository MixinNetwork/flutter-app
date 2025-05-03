import 'package:drift/drift.dart';

import '../signal_database.dart';

part 'signed_pre_key_dao.g.dart';

@DriftAccessor()
class SignedPreKeyDao extends DatabaseAccessor<SignalDatabase>
    with _$SignedPreKeyDaoMixin {
  SignedPreKeyDao(super.db);

  Future<SignedPrekey?> getSignedPreKey(int signedPreKeyId) async =>
      (select(
        db.signedPrekeys,
      )..where((tbl) => tbl.prekeyId.equals(signedPreKeyId))).getSingleOrNull();

  Future<List<SignedPrekey>> getSignedPreKeyList() async =>
      select(db.signedPrekeys).get();

  Future<int> deleteByPreKeyId(int signedPreKeyId) =>
      (delete(db.signedPrekeys)
        ..where((tbl) => tbl.prekeyId.equals(signedPreKeyId))).go();

  Future insert(SignedPrekeysCompanion signedPreKey) => into(
    db.signedPrekeys,
  ).insert(signedPreKey, mode: InsertMode.insertOrReplace);
}
