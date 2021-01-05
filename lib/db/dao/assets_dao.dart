import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'assets_dao.g.dart';

@UseDao(tables: [Assets])
class AssetssDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  AssetssDao(MixinDatabase db) : super(db);
}
