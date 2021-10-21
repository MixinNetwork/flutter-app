import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'app_dao.g.dart';

@DriftAccessor(tables: [Apps])
class AppDao extends DatabaseAccessor<MixinDatabase> with _$AppDaoMixin {
  AppDao(MixinDatabase db) : super(db);

  Future<int> insert(App app) => into(db.apps).insertOnConflictUpdate(app);

  Future deleteApp(App app) => delete(db.apps).delete(app);

  Future<App?> findAppById(String appId) async =>
      (select(db.apps)..where((tbl) => tbl.appId.equals(appId)))
          .getSingleOrNull();

  SimpleSelectStatement<Apps, App> appInIds(Iterable<String> ids) =>
      select(db.apps)..where((tbl) => tbl.appId.isIn(ids));
}
