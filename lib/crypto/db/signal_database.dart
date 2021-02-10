import 'dart:io';

import 'package:moor/moor.dart';
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'dao/identity_dao.dart';

part 'signal_database.g.dart';

@UseMoor(include: {'signal.moor', './dao/identity.moor'}, daos: [IdentityDao])
class SignalDatabase extends _$SignalDatabase {
  SignalDatabase() : super(_openConnection());

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
