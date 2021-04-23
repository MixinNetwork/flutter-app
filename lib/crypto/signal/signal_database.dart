import 'dart:io';

import 'package:flutter_app/crypto/signal/dao/identity_dao.dart';
import 'package:flutter_app/crypto/signal/dao/pre_key_dao.dart';
import 'package:flutter_app/crypto/signal/dao/sender_key_dao.dart';
import 'package:flutter_app/crypto/signal/dao/session_dao.dart';
import 'package:flutter_app/crypto/signal/dao/signed_pre_key_dao.dart';
import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'signal_database.g.dart';

@UseMoor(include: {
  'moor/signal.moor',
  'moor/dao/identity.moor',
  'moor/dao/pre_key.moor',
  'moor/dao/sender_key.moor',
  'moor/dao/session.moor',
  'moor/dao/signed_pre_key.moor',
}, daos: [
  IdentityDao,
  PreKeyDao,
  SenderKeyDao,
  SessionDao,
  SignedPreKeyDao,
])
class SignalDatabase extends _$SignalDatabase {
  SignalDatabase._() : super(_openConnection());

  static SignalDatabase? _instance;

  static SignalDatabase get get => _instance ??= SignalDatabase._();

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'signal.db'));
    return VmDatabase(file);
  });
}
