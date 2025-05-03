import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../../utils/file.dart';
import 'dao/identity_dao.dart';
import 'dao/pre_key_dao.dart';
import 'dao/ratchet_sender_key_dao.dart';
import 'dao/sender_key_dao.dart';
import 'dao/session_dao.dart';
import 'dao/signed_pre_key_dao.dart';

part 'signal_database.g.dart';

@DriftDatabase(
  include: {
    'moor/signal.drift',
    'moor/dao/identity.drift',
    'moor/dao/pre_key.drift',
    'moor/dao/sender_key.drift',
    'moor/dao/session.drift',
    'moor/dao/signed_pre_key.drift',
    'moor/dao/ratchet_sender_key.drift',
  },
  daos: [
    IdentityDao,
    PreKeyDao,
    SenderKeyDao,
    SessionDao,
    SignedPreKeyDao,
    RatchetSenderKeyDao,
  ],
)
class SignalDatabase extends _$SignalDatabase {
  SignalDatabase._() : super(_openConnection());

  static SignalDatabase? _instance;

  static SignalDatabase get get => _instance ??= SignalDatabase._();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      if (executor.dialect == SqlDialect.sqlite) {
        await customStatement('PRAGMA journal_mode=WAL');
        await customStatement('PRAGMA synchronous=NORMAL');
        await customStatement('PRAGMA foreign_keys=ON');
      }
    },
  );

  Future<void> clear() => transaction(() async {
    await customStatement('PRAGMA wal_checkpoint(FULL)');
    for (final table in allTables) {
      await delete(table).go();
    }
  });
}

LazyDatabase _openConnection() => LazyDatabase(() {
  final dbFolder = mixinDocumentsDirectory;
  final file = File(p.join(dbFolder.path, 'signal.db'));
  return NativeDatabase(file);
});
