import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../enum/property_group.dart';
import '../../ui/provider/setting_provider.dart';
import '../../utils/file.dart';
import '../util/open_database.dart';
import 'converter/app_property_group_converter.dart';
import 'dao/app_key_value_dao.dart';

part 'app_database.g.dart';

/// The database for application, shared by all users.
@DriftDatabase(
  include: {'drift/app.drift'},
  daos: [
    AppKeyValueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.connect({
    bool fromMainIsolate = false,
  }) {
    final dbFilePath = p.join(mixinDocumentsDirectory.path, 'app.db');
    return AppDatabase(LazyDatabase(() async {
      final queryExecutor = await createOrConnectDriftIsolate(
        portName: 'one_mixin_drift_app',
        debugName: 'isolate_drift_app',
        fromMainIsolate: fromMainIsolate,
        dbFile: File(dbFilePath),
      );
      return queryExecutor.connect();
    }));
  }

  late final AppSettingKeyValue settingKeyValue =
      AppSettingKeyValue(appKeyValueDao);

  @override
  int get schemaVersion => 1;
}
