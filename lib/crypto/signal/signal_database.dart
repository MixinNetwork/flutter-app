import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;

import '../../utils/file.dart';
import 'dao/identity_dao.dart';
import 'dao/pre_key_dao.dart';
import 'dao/ratchet_sender_key_dao.dart';
import 'dao/sender_key_dao.dart';
import 'dao/session_dao.dart';
import 'dao/signed_pre_key_dao.dart';

part 'signal_database.g.dart';

@UseMoor(include: {
  'moor/signal.moor',
  'moor/dao/identity.moor',
  'moor/dao/pre_key.moor',
  'moor/dao/sender_key.moor',
  'moor/dao/session.moor',
  'moor/dao/signed_pre_key.moor',
  'moor/dao/ratchet_sender_key.moor',
}, daos: [
  IdentityDao,
  PreKeyDao,
  SenderKeyDao,
  SessionDao,
  SignedPreKeyDao,
  RatchetSenderKeyDao,
])
class SignalDatabase extends _$SignalDatabase {
  SignalDatabase._() : super(_openConnection());

  static SignalDatabase? _instance;

  static SignalDatabase get get => _instance ??= SignalDatabase._();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (_) async {
        if (executor.dialect == SqlDialect.sqlite) {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA foreign_keys=ON');
        }
      });

  Future<void> clear() => transaction(() async {
        for (var table in allTables) {
          await delete(table).go();
        }
      });
}

LazyDatabase _openConnection() => LazyDatabase(() {
      final dbFolder = mixinDocumentsDirectory;
      final file = File(p.join(dbFolder.path, 'signal.db'));
      return VmDatabase(file);
    });
