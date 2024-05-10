// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataToken _$TransferDataTokenFromJson(Map<String, dynamic> json) =>
    TransferDataToken(
      assetId: json['asset_id'] as String,
      asset: json['kernel_asset_id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String,
      priceBtc: json['price_btc'] as String,
      priceUsd: json['price_usd'] as String,
      chainId: json['chain_id'] as String,
      changeUsd: json['change_usd'] as String,
      changeBtc: json['change_btc'] as String,
      confirmations: (json['confirmations'] as num).toInt(),
      assetKey: json['asset_key'] as String,
      dust: json['dust'] as String,
      collectionHash: json['collection_hash'] as String?,
    );

Map<String, dynamic> _$TransferDataTokenToJson(TransferDataToken instance) =>
    <String, dynamic>{
      'asset_id': instance.assetId,
      'kernel_asset_id': instance.asset,
      'symbol': instance.symbol,
      'name': instance.name,
      'icon_url': instance.iconUrl,
      'price_btc': instance.priceBtc,
      'price_usd': instance.priceUsd,
      'chain_id': instance.chainId,
      'change_usd': instance.changeUsd,
      'change_btc': instance.changeBtc,
      'confirmations': instance.confirmations,
      'asset_key': instance.assetKey,
      'dust': instance.dust,
      'collection_hash': instance.collectionHash,
    };
