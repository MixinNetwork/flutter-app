import 'dart:async';

import 'package:drift/drift.dart';

import '../../db/util/open_database.dart';
import '../../utils/logger.dart';
import 'dao/identity_dao.dart';
import 'dao/pre_key_dao.dart';
import 'dao/ratchet_sender_key_dao.dart';
import 'dao/sender_key_dao.dart';
import 'dao/session_dao.dart';
import 'dao/signed_pre_key_dao.dart';

part 'signal_database.g.dart';

@DriftDatabase(include: {
  'moor/signal.drift',
  'moor/dao/identity.drift',
  'moor/dao/pre_key.drift',
  'moor/dao/sender_key.drift',
  'moor/dao/session.drift',
  'moor/dao/signed_pre_key.drift',
  'moor/dao/ratchet_sender_key.drift'
}, daos: [
  IdentityDao,
  PreKeyDao,
  SenderKeyDao,
  SessionDao,
  SignedPreKeyDao,
  RatchetSenderKeyDao,
])
class SignalDatabase extends _$SignalDatabase {
  SignalDatabase._(super.e);


  static Future<SignalDatabase> connect({
    required String identityNumber,
    required bool fromMainIsolate,
  }) async {
    final executor = await openQueryExecutor(
      identityNumber: identityNumber,
      dbName: 'signal',
      fromMainIsolate: fromMainIsolate,
      readCount: 0,
    );
    return SignalDatabase._(executor);
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (_) async {
        if (executor.dialect == SqlDialect.sqlite) {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA synchronous=NORMAL');
          await customStatement('PRAGMA foreign_keys=ON');
        }
      });

  Future<void> clear() => transaction(() async {
        i('clear signal database');
        await customStatement('PRAGMA wal_checkpoint(FULL)');
        for (final table in allTables) {
          await delete(table).go();
        }
      });
}
