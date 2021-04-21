import 'package:moor/moor.dart';

import '../signal_database.dart';

part 'signed_pre_key_dao.g.dart';

@UseDao(tables: [SignedPrekeys])
class SignedPreKeyDao extends DatabaseAccessor<SignalDatabase> {
  SignedPreKeyDao(SignalDatabase db) : super(db);

  Future<SignedPrekey?> getSignedPreKey(int signedPreKeyId) async =>
      (select(db.signedPrekeys)
            ..where((tbl) => tbl.prekeyId.equals(signedPreKeyId)))
          .getSingleOrNull();

  Future<List<SignedPrekey>> getSignedPreKeyList() async =>
      select(db.signedPrekeys).get();

  Future<int> deleteByPreKeyId(int signedPreKeyId) => (delete(db.signedPrekeys)
        ..where((tbl) => tbl.prekeyId.equals(signedPreKeyId)))
      .go();

  Future insert(SignedPrekey signedPreKey) =>
      into(db.signedPrekeys).insert(signedPreKey);
}
