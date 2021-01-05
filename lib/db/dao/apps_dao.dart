import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'apps_dao.g.dart';

@UseDao(tables: [Apps])
class AppsDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  AppsDao(MixinDatabase db) : super(db);
}
