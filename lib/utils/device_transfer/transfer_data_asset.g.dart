// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataAsset _$TransferDataAssetFromJson(Map<String, dynamic> json) =>
    TransferDataAsset(
      assetId: json['asset_id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String,
      balance: json['balance'] as String,
      destination: json['destination'] as String,
      priceBtc: json['price_btc'] as String,
      priceUsd: json['price_usd'] as String,
      chainId: json['chain_id'] as String,
      changeUsd: json['change_usd'] as String,
      changeBtc: json['change_btc'] as String,
      confirmations: (json['confirmations'] as num).toInt(),
      tag: json['tag'] as String?,
      assetKey: json['asset_key'] as String?,
      reserve: json['reserve'] as String?,
    );

Map<String, dynamic> _$TransferDataAssetToJson(TransferDataAsset instance) =>
    <String, dynamic>{
      'asset_id': instance.assetId,
      'symbol': instance.symbol,
      'name': instance.name,
      'icon_url': instance.iconUrl,
      'balance': instance.balance,
      'destination': instance.destination,
      'tag': instance.tag,
      'price_btc': instance.priceBtc,
      'price_usd': instance.priceUsd,
      'chain_id': instance.chainId,
      'change_usd': instance.changeUsd,
      'change_btc': instance.changeBtc,
      'confirmations': instance.confirmations,
      'asset_key': instance.assetKey,
      'reserve': instance.reserve,
    };
