import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../enum/property_group.dart';
import '../../utils/file.dart';
import '../util/open_database.dart';
import 'converter/app_property_group_converter.dart';

part 'app_database.g.dart';

/// The database for application, shared by all users.
@DriftDatabase(
  include: {'drift/app.drift'},
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static Future<AppDatabase> connect({
    bool fromMainIsolate = false,
  }) async {
    final dbFilePath = p.join(mixinDocumentsDirectory.path, 'app.db');
    final queryExecutor = await createOrConnectDriftIsolate(
      portName: 'one_mixin_drift_app',
      debugName: 'isolate_drift_app',
      fromMainIsolate: fromMainIsolate,
      dbFile: File(dbFilePath),
    );
    return AppDatabase(await queryExecutor.connect());
  }

  @override
  int get schemaVersion => 1;
}
