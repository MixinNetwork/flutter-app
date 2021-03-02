import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'apps_dao.g.dart';

@UseDao(tables: [Apps])
class AppsDao extends DatabaseAccessor<MixinDatabase> with _$AppsDaoMixin {
  AppsDao(MixinDatabase db) : super(db);

  Future<int> insert(App app) => into(db.apps).insertOnConflictUpdate(app);

  Future deleteApp(App app) => delete(db.apps).delete(app);

  Future<App?> findUserById(String appId) async{
    final list = await (select(db.apps)..where((tbl) => tbl.appId.equals(appId))).get();
    return list.isEmpty ? null : list.first;
  }
}
