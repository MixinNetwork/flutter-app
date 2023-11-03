import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart' as db;

part 'transfer_data_token.g.dart';

@JsonSerializable()
class TransferDataToken {
  TransferDataToken({
    required this.assetId,
    required this.asset,
    required this.symbol,
    required this.name,
    required this.iconUrl,
    required this.priceBtc,
    required this.priceUsd,
    required this.chainId,
    required this.changeUsd,
    required this.changeBtc,
    required this.confirmations,
    required this.assetKey,
    required this.dust,
  });

  factory TransferDataToken.fromDbToken(db.Token token) => TransferDataToken(
        assetId: token.assetId,
        asset: token.kernelAssetId,
        symbol: token.symbol,
        name: token.name,
        iconUrl: token.iconUrl,
        priceBtc: token.priceBtc,
        priceUsd: token.priceUsd,
        chainId: token.chainId,
        changeUsd: token.changeUsd,
        changeBtc: token.changeBtc,
        confirmations: token.confirmations,
        assetKey: token.assetKey,
        dust: token.dust,
      );

  factory TransferDataToken.fromJson(Map<String, dynamic> json) =>
      _$TransferDataTokenFromJson(json);

  @JsonKey(name: 'asset_id')
  final String assetId;
  @JsonKey(name: 'kernel_asset_id')
  final String asset;
  @JsonKey(name: 'symbol')
  final String symbol;
  @JsonKey(name: 'name')
  final String name;
  @JsonKey(name: 'icon_url')
  final String iconUrl;
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
  final String assetKey;
  @JsonKey(name: 'dust')
  final String dust;

  Map<String, dynamic> toJson() => _$TransferDataTokenToJson(this);

  db.Token toDbToken() => db.Token(
        assetId: assetId,
        kernelAssetId: asset,
        symbol: symbol,
        name: name,
        iconUrl: iconUrl,
        priceBtc: priceBtc,
        priceUsd: priceUsd,
        chainId: chainId,
        changeUsd: changeUsd,
        changeBtc: changeBtc,
        confirmations: confirmations,
        assetKey: assetKey,
        dust: dust,
      );
}
