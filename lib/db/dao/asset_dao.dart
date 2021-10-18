import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;
import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'asset_dao.g.dart';

extension AssetConverter on sdk.Asset {
  AssetsCompanion get asAssetsCompanion => AssetsCompanion.insert(
        assetId: assetId,
        symbol: symbol,
        name: name,
        iconUrl: iconUrl,
        balance: balance,
        destination: destination ?? '',
        tag: Value(tag),
        assetKey: Value(assetKey),
        priceBtc: priceBtc,
        priceUsd: priceUsd,
        chainId: chainId,
        changeUsd: changeUsd,
        changeBtc: changeBtc,
        confirmations: confirmations,
        reserve: Value(reserve),
      );
}

@UseDao(tables: [Assets])
class AssetDao extends DatabaseAccessor<MixinDatabase> with _$AssetDaoMixin {
  AssetDao(MixinDatabase db) : super(db);

  Future<int> insert(Asset asset) =>
      into(db.assets).insertOnConflictUpdate(asset);

  Future<int> insertSdkAsset(sdk.Asset asset) =>
      into(db.assets).insertOnConflictUpdate(asset.asAssetsCompanion);

  Future deleteAsset(Asset asset) => delete(db.assets).delete(asset);

  Future<Asset?> findAssetById(String assetId) =>
      (select(db.assets)..where((t) => t.assetId.equals(assetId)))
          .getSingleOrNull();

  SimpleSelectStatement<Assets, Asset> assetById(String assetId) =>
      select(db.assets)
        ..where((t) => t.assetId.equals(assetId))
        ..limit(1);
}
