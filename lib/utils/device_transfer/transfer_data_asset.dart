import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart' as db;

part 'transfer_data_asset.g.dart';

@JsonSerializable()
class TransferDataAsset {
  TransferDataAsset({
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.iconUrl,
    required this.balance,
    required this.destination,
    required this.priceBtc,
    required this.priceUsd,
    required this.chainId,
    required this.changeUsd,
    required this.changeBtc,
    required this.confirmations,
    this.tag,
    this.assetKey,
    this.reserve,
  });

  factory TransferDataAsset.fromJson(Map<String, dynamic> json) =>
      _$TransferDataAssetFromJson(json);

  factory TransferDataAsset.fromDbAsset(db.Asset a) => TransferDataAsset(
    assetId: a.assetId,
    symbol: a.symbol,
    name: a.name,
    iconUrl: a.iconUrl,
    balance: a.balance,
    destination: a.destination,
    priceBtc: a.priceBtc,
    priceUsd: a.priceUsd,
    chainId: a.chainId,
    changeUsd: a.changeUsd,
    changeBtc: a.changeBtc,
    confirmations: a.confirmations,
    tag: a.tag,
    assetKey: a.assetKey,
    reserve: a.reserve,
  );

  @JsonKey(name: 'asset_id')
  final String assetId;

  final String symbol;
  final String name;

  @JsonKey(name: 'icon_url')
  final String iconUrl;
  final String balance;
  final String destination;
  final String? tag;

  @JsonKey(name: 'price_btc')
  final String priceBtc;

  @JsonKey(name: 'price_usd')
  final String priceUsd;

  @JsonKey(name: 'chain_id')
  final String chainId;

  @JsonKey(name: 'change_usd')
  final String changeUsd;

  @JsonKey(name: 'change_btc')
  final String changeBtc;

  @JsonKey(name: 'confirmations')
  final int confirmations;

  @JsonKey(name: 'asset_key')
  final String? assetKey;

  @JsonKey(name: 'reserve')
  final String? reserve;

  Map<String, dynamic> toJson() => _$TransferDataAssetToJson(this);

  db.Asset toDbAsset() => db.Asset(
    assetId: assetId,
    symbol: symbol,
    name: name,
    iconUrl: iconUrl,
    balance: balance,
    destination: destination,
    priceBtc: priceBtc,
    priceUsd: priceUsd,
    chainId: chainId,
    changeUsd: changeUsd,
    changeBtc: changeBtc,
    confirmations: confirmations,
    tag: tag,
    assetKey: assetKey,
    reserve: reserve,
  );

  @override
  String toString() => 'TransferDataAsset(assetId: $assetId)';
}
