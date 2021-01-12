import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'assets_dao.g.dart';

@UseDao(tables: [Assets])
class AssetsDao extends DatabaseAccessor<MixinDatabase> with _$AssetsDaoMixin {
  AssetsDao(MixinDatabase db) : super(db);

  Future<int> insert(Asset asset) => into(db.assets).insertOnConflictUpdate(asset);

  Future deleteAsset(Asset asset) => delete(db.assets).delete(asset);
}
