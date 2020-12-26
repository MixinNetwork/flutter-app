import 'dart:io';

import 'package:moor/moor.dart';
// These imports are only needed to open the database
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'mixin_database.g.dart';

@UseMoor(
  include: {'mixin.moor'},
)
class MixinDatabase extends _$MixinDatabase {
  MixinDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mixin.db'));
    return VmDatabase(file);
  });
}
