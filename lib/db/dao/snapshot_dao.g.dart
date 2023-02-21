// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshot_dao.dart';

// ignore_for_file: type=lint
mixin _$SnapshotDaoMixin on DatabaseAccessor<MixinDatabase> {
  Snapshots get snapshots => attachedDatabase.snapshots;
  Users get users => attachedDatabase.users;
  Assets get assets => attachedDatabase.assets;
  Chains get chains => attachedDatabase.chains;
  Fiats get fiats => attachedDatabase.fiats;
  Selectable<SnapshotItem> snapshotItems(
      String currentFiat,
      SnapshotItems$where where,
      SnapshotItems$order order,
      SnapshotItems$limit limit) {
    var $arrayStartIndex = 2;
    final generatedwhere = $write(
        where(
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'opponent'),
            alias(this.assets, 'asset'),
            alias(this.chains, 'chain'),
            alias(this.fiats, 'fiat')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedorder = $write(
        order?.call(
                alias(this.snapshots, 'snapshot'),
                alias(this.users, 'opponent'),
                alias(this.assets, 'asset'),
                alias(this.chains, 'chain'),
                alias(this.fiats, 'fiat')) ??
            const OrderBy.nothing(),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'opponent'),
            alias(this.assets, 'asset'),
            alias(this.chains, 'chain'),
            alias(this.fiats, 'fiat')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT snapshot.*, opponent.avatar_url, opponent.full_name AS opponent_ful_name, asset.price_usd, asset.chain_id, asset.symbol, asset.name AS symbolName, asset.tag, asset.confirmations AS asset_confirmations, asset.icon_url AS symbolIconUrl, chain.icon_url AS chainIconUrl, fiat.rate AS fiatRate FROM snapshots AS snapshot LEFT JOIN users AS opponent ON opponent.user_id = snapshot.opponent_id LEFT JOIN assets AS asset ON asset.asset_id = snapshot.asset_id LEFT JOIN chains AS chain ON asset.chain_id = chain.chain_id LEFT JOIN fiats AS fiat ON fiat.code = ?1 WHERE ${generatedwhere.sql} ${generatedorder.sql} ${generatedlimit.sql}',
        variables: [
          Variable<String>(currentFiat),
          ...generatedwhere.introducedVariables,
          ...generatedorder.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          users,
          assets,
          chains,
          fiats,
          snapshots,
          ...generatedwhere.watchedTables,
          ...generatedorder.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) {
      return SnapshotItem(
        snapshotId: row.read<String>('snapshot_id'),
        traceId: row.readNullable<String>('trace_id'),
        type: row.read<String>('type'),
        assetId: row.read<String>('asset_id'),
        amount: row.read<String>('amount'),
        createdAt:
            Snapshots.$convertercreatedAt.fromSql(row.read<int>('created_at')),
        opponentId: row.readNullable<String>('opponent_id'),
        transactionHash: row.readNullable<String>('transaction_hash'),
        sender: row.readNullable<String>('sender'),
        receiver: row.readNullable<String>('receiver'),
        memo: row.readNullable<String>('memo'),
        confirmations: row.readNullable<int>('confirmations'),
        avatarUrl: row.readNullable<String>('avatar_url'),
        opponentFulName: row.readNullable<String>('opponent_ful_name'),
        priceUsd: row.readNullable<String>('price_usd'),
        chainId: row.readNullable<String>('chain_id'),
        symbol: row.readNullable<String>('symbol'),
        symbolName: row.readNullable<String>('symbolName'),
        tag: row.readNullable<String>('tag'),
        assetConfirmations: row.readNullable<int>('asset_confirmations'),
        symbolIconUrl: row.readNullable<String>('symbolIconUrl'),
        chainIconUrl: row.readNullable<String>('chainIconUrl'),
        fiatRate: row.readNullable<double>('fiatRate'),
      );
    });
  }
}

class SnapshotItem {
  final String snapshotId;
  final String? traceId;
  final String type;
  final String assetId;
  final String amount;
  final DateTime createdAt;
  final String? opponentId;
  final String? transactionHash;
  final String? sender;
  final String? receiver;
  final String? memo;
  final int? confirmations;
  final String? avatarUrl;
  final String? opponentFulName;
  final String? priceUsd;
  final String? chainId;
  final String? symbol;
  final String? symbolName;
  final String? tag;
  final int? assetConfirmations;
  final String? symbolIconUrl;
  final String? chainIconUrl;
  final double? fiatRate;
  SnapshotItem({
    required this.snapshotId,
    this.traceId,
    required this.type,
    required this.assetId,
    required this.amount,
    required this.createdAt,
    this.opponentId,
    this.transactionHash,
    this.sender,
    this.receiver,
    this.memo,
    this.confirmations,
    this.avatarUrl,
    this.opponentFulName,
    this.priceUsd,
    this.chainId,
    this.symbol,
    this.symbolName,
    this.tag,
    this.assetConfirmations,
    this.symbolIconUrl,
    this.chainIconUrl,
    this.fiatRate,
  });
  @override
  int get hashCode => Object.hashAll([
        snapshotId,
        traceId,
        type,
        assetId,
        amount,
        createdAt,
        opponentId,
        transactionHash,
        sender,
        receiver,
        memo,
        confirmations,
        avatarUrl,
        opponentFulName,
        priceUsd,
        chainId,
        symbol,
        symbolName,
        tag,
        assetConfirmations,
        symbolIconUrl,
        chainIconUrl,
        fiatRate
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotItem &&
          other.snapshotId == this.snapshotId &&
          other.traceId == this.traceId &&
          other.type == this.type &&
          other.assetId == this.assetId &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt &&
          other.opponentId == this.opponentId &&
          other.transactionHash == this.transactionHash &&
          other.sender == this.sender &&
          other.receiver == this.receiver &&
          other.memo == this.memo &&
          other.confirmations == this.confirmations &&
          other.avatarUrl == this.avatarUrl &&
          other.opponentFulName == this.opponentFulName &&
          other.priceUsd == this.priceUsd &&
          other.chainId == this.chainId &&
          other.symbol == this.symbol &&
          other.symbolName == this.symbolName &&
          other.tag == this.tag &&
          other.assetConfirmations == this.assetConfirmations &&
          other.symbolIconUrl == this.symbolIconUrl &&
          other.chainIconUrl == this.chainIconUrl &&
          other.fiatRate == this.fiatRate);
  @override
  String toString() {
    return (StringBuffer('SnapshotItem(')
          ..write('snapshotId: $snapshotId, ')
          ..write('traceId: $traceId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('opponentId: $opponentId, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('sender: $sender, ')
          ..write('receiver: $receiver, ')
          ..write('memo: $memo, ')
          ..write('confirmations: $confirmations, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('opponentFulName: $opponentFulName, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('chainId: $chainId, ')
          ..write('symbol: $symbol, ')
          ..write('symbolName: $symbolName, ')
          ..write('tag: $tag, ')
          ..write('assetConfirmations: $assetConfirmations, ')
          ..write('symbolIconUrl: $symbolIconUrl, ')
          ..write('chainIconUrl: $chainIconUrl, ')
          ..write('fiatRate: $fiatRate')
          ..write(')'))
        .toString();
  }
}

typedef SnapshotItems$where = Expression<bool> Function(
    Snapshots snapshot, Users opponent, Assets asset, Chains chain, Fiats fiat);
typedef SnapshotItems$order = OrderBy Function(
    Snapshots snapshot, Users opponent, Assets asset, Chains chain, Fiats fiat);
typedef SnapshotItems$limit = Limit Function(
    Snapshots snapshot, Users opponent, Assets asset, Chains chain, Fiats fiat);
