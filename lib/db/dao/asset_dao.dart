import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'asset_dao.g.dart';

extension AssetConverter on sdk.Asset {
  AssetsCompanion get asAssetsCompanion {
    String? destination = '';
    if (depositEntries?.isNotEmpty == true) {
      // ignore: prefer-first
      destination = depositEntries?[0].destination ?? destination;
    }
    return AssetsCompanion.insert(
      assetId: assetId,
      symbol: displaySymbol,
      name: displayName,
      iconUrl: iconUrl,
      balance: balance,
      destination: destination,
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
}

@DriftAccessor(include: {'../moor/dao/asset.drift'})
class AssetDao extends DatabaseAccessor<MixinDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Future<int> insertSdkAsset(sdk.Asset asset) =>
      into(db.assets).insertOnConflictUpdate(asset.asAssetsCompanion);

  Future<int> insertAsset(Asset asset) =>
      into(db.assets).insert(asset, mode: InsertMode.insertOrIgnore);

  Future deleteAsset(Asset asset) => delete(db.assets).delete(asset);

  Future<Asset?> findAssetById(String assetId) =>
      (select(db.assets)..where((t) => t.assetId.equals(assetId)))
          .getSingleOrNull();

  SimpleSelectStatement<Assets, Asset> assetById(String assetId) =>
      select(db.assets)
        ..where((t) => t.assetId.equals(assetId))
        ..limit(1);

  Future<List<Asset>> getAssets() => select(db.assets).get();
}
