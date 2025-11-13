import 'package:drift/drift.dart';

import '../extension/db.dart';
import '../mixin_database.dart';

part 'app_dao.g.dart';

extension IsEncryptedExtension on App {
  bool get isEncrypted => capabilities?.contains('ENCRYPTED') == true;
}

@DriftAccessor()
class AppDao extends DatabaseAccessor<MixinDatabase> with _$AppDaoMixin {
  AppDao(super.db);

  Future<int> insert(App app, {bool updateIfConflict = true}) =>
      into(db.apps).simpleInsert(app, updateIfConflict: updateIfConflict);

  Future deleteApp(App app) => delete(db.apps).delete(app);

  Future<App?> findAppById(String appId) async => (select(
    db.apps,
  )..where((tbl) => tbl.appId.equals(appId))).getSingleOrNull();

  SimpleSelectStatement<Apps, App> appInIds(Iterable<String> ids) =>
      select(db.apps)..where((tbl) => tbl.appId.isIn(ids));

  Future<List<App>> getApps({required int offset, required int limit}) async =>
      (select(db.apps)
            ..orderBy([
              (t) => OrderingTerm(expression: t.rowId, mode: OrderingMode.desc),
            ])
            ..limit(limit, offset: offset))
          .get();

  Future<int> getAppsCount() async => db
      .customSelect('SELECT COUNT(1) as _result FROM apps')
      .map((p0) => p0.read<int>('_result'))
      .getSingle();
}
