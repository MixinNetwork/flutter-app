import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../db/util/open_database.dart';
import '../../utils/file.dart';
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

  static Future<void> _removeLegacySignalDatabase() async {
    final dbFolder = mixinDocumentsDirectory.path;
    const dbFiles = ['signal.db', 'signal.db-shm', 'signal.db-wal'];
    final files = dbFiles.map((e) => File(p.join(dbFolder, e)));
    for (final file in files) {
      try {
        if (file.existsSync()) {
          i('remove legacy signal database: ${file.path}');
          await file.delete();
        }
      } catch (error, stacktrace) {
        e('_removeLegacySignalDatabase ${file.path} error: $error, stacktrace: $stacktrace');
      }
    }
  }

  static Future<void> _migrationLegacySignalDatabaseIfNecessary(
      String identityNumber) async {
    final dbFolder = p.join(mixinDocumentsDirectory.path, identityNumber);

    final dbFile = File(p.join(dbFolder, 'signal.db'));
    // migration only when new database file not exists.
    if (dbFile.existsSync()) {
      return _removeLegacySignalDatabase();
    }

    final legacyDbFolder = mixinDocumentsDirectory.path;
    final legacyDbFile = File(p.join(legacyDbFolder, 'signal.db'));
    if (!legacyDbFile.existsSync()) {
      return;
    }
    const dbFiles = ['signal.db', 'signal.db-shm', 'signal.db-wal'];
    final legacyFiles = dbFiles.map((e) => File(p.join(legacyDbFolder, e)));
    var hasError = false;
    for (final file in legacyFiles) {
      try {
        final newLocation = p.join(dbFolder, p.basename(file.path));
        // delete new location file if exists
        final newFile = File(newLocation);
        if (newFile.existsSync()) {
          await newFile.delete();
        }
        if (file.existsSync()) {
          await file.copy(newLocation);
        }
        i('migrate legacy signal database: ${file.path}');
      } catch (error, stacktrace) {
        e('_migrationLegacySignalDatabaseIfNecessary ${file.path} error: $error, stacktrace: $stacktrace');
        hasError = true;
      }
    }
    if (hasError) {
      // migration error. remove copied database file.
      for (final name in dbFiles) {
        final file = File(p.join(dbFolder, name));
        if (file.existsSync()) {
          await file.delete();
        }
      }
    }
    return _removeLegacySignalDatabase();
  }

  static Future<SignalDatabase> connect({
    required String identityNumber,
    required bool openForLogin,
    required bool fromMainIsolate,
  }) async {
    if (openForLogin) {
      // delete old database file
      await _removeLegacySignalDatabase();
    } else {
      await _migrationLegacySignalDatabaseIfNecessary(identityNumber);
    }
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
