import 'dart:io';

import 'package:moor/moor.dart';
// These imports are only needed to open the database
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'signal_database.g.dart';

@UseMoor(
  include: {'signal.moor'},
)
class SignalDb extends _$SignalDb {
  SignalDb() : super(_openConnection());

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
