import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'assets_dao.g.dart';

@UseDao(tables: [Assets])
class AssetsDao extends DatabaseAccessor<MixinDatabase> with _$AssetsDaoMixin {
  AssetsDao(MixinDatabase db) : super(db);

  Future<int> insert(Asset asset) =>
      into(db.assets).insertOnConflictUpdate(asset);

  Future deleteAsset(Asset asset) => delete(db.assets).delete(asset);

  Future<Asset?> findAssetById(String assetId) =>
      (select(db.assets)..where((t) => t.assetId.equals(assetId)))
          .getSingleOrNull();
}
