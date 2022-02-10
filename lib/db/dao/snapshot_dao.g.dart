// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshot_dao.dart';

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$SnapshotDaoMixin on DatabaseAccessor<MixinDatabase> {
  Conversations get conversations => attachedDatabase.conversations;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Jobs get jobs => attachedDatabase.jobs;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
  Messages get messages => attachedDatabase.messages;
  Participants get participants => attachedDatabase.participants;
  StickerAlbums get stickerAlbums => attachedDatabase.stickerAlbums;
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Circles get circles => attachedDatabase.circles;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  MessagesFtsV2 get messagesFtsV2 => attachedDatabase.messagesFtsV2;
  MessagesHistory get messagesHistory => attachedDatabase.messagesHistory;
  Offsets get offsets => attachedDatabase.offsets;
  ParticipantSession get participantSession =>
      attachedDatabase.participantSession;
  ResendSessionMessages get resendSessionMessages =>
      attachedDatabase.resendSessionMessages;
  SentSessionSenderKeys get sentSessionSenderKeys =>
      attachedDatabase.sentSessionSenderKeys;
  Snapshots get snapshots => attachedDatabase.snapshots;
  StickerRelationships get stickerRelationships =>
      attachedDatabase.stickerRelationships;
  Stickers get stickers => attachedDatabase.stickers;
  Users get users => attachedDatabase.users;
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  Selectable<SnapshotItem> snapshotItems(
      String currentFiat,
      Expression<bool?> Function(Snapshots snapshot, Users opponent,
              Assets asset, Assets tempAsset, Fiats fiat)
          where,
      OrderBy Function(Snapshots snapshot, Users opponent, Assets asset,
              Assets tempAsset, Fiats fiat)
          order,
      Limit Function(Snapshots snapshot, Users opponent, Assets asset,
              Assets tempAsset, Fiats fiat)
          limit) {
    var $arrayStartIndex = 2;
    final generatedwhere = $write(
        where(
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'opponent'),
            alias(this.assets, 'asset'),
            alias(this.assets, 'tempAsset'),
            alias(this.fiats, 'fiat')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedorder = $write(
        order(
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'opponent'),
            alias(this.assets, 'asset'),
            alias(this.assets, 'tempAsset'),
            alias(this.fiats, 'fiat')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'opponent'),
            alias(this.assets, 'asset'),
            alias(this.assets, 'tempAsset'),
            alias(this.fiats, 'fiat')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT snapshot.*, opponent.avatar_url, opponent.full_name AS opponent_ful_name, asset.price_usd, asset.chain_id, asset.symbol, asset.name AS symbolName, asset.tag, asset.confirmations AS asset_confirmations, asset.icon_url AS symbolIconUrl, tempAsset.icon_url AS chainIconUrl, fiat.rate AS fiatRate FROM snapshots AS snapshot LEFT JOIN users AS opponent ON opponent.user_id = snapshot.opponent_id LEFT JOIN assets AS asset ON asset.asset_id = snapshot.asset_id LEFT JOIN assets AS tempAsset ON asset.chain_id = tempAsset.asset_id LEFT JOIN fiats AS fiat ON fiat.code = ?1 WHERE ${generatedwhere.sql} ${generatedorder.sql} ${generatedlimit.sql}',
        variables: [
          Variable<String>(currentFiat),
          ...generatedwhere.introducedVariables,
          ...generatedorder.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          users,
          assets,
          fiats,
          snapshots,
          ...generatedwhere.watchedTables,
          ...generatedorder.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) {
      return SnapshotItem(
        snapshotId: row.read<String>('snapshot_id'),
        type: row.read<String>('type'),
        assetId: row.read<String>('asset_id'),
        amount: row.read<String>('amount'),
        createdAt:
            Snapshots.$converter0.mapToDart(row.read<int>('created_at'))!,
        opponentId: row.read<String?>('opponent_id'),
        transactionHash: row.read<String?>('transaction_hash'),
        sender: row.read<String?>('sender'),
        receiver: row.read<String?>('receiver'),
        memo: row.read<String?>('memo'),
        confirmations: row.read<int?>('confirmations'),
        avatarUrl: row.read<String?>('avatar_url'),
        opponentFulName: row.read<String?>('opponent_ful_name'),
        priceUsd: row.read<String?>('price_usd'),
        chainId: row.read<String?>('chain_id'),
        symbol: row.read<String?>('symbol'),
        symbolName: row.read<String?>('symbolName'),
        tag: row.read<String?>('tag'),
        assetConfirmations: row.read<int?>('asset_confirmations'),
        symbolIconUrl: row.read<String?>('symbolIconUrl'),
        chainIconUrl: row.read<String?>('chainIconUrl'),
        fiatRate: row.read<double?>('fiatRate'),
      );
    });
  }
}

class SnapshotItem {
  final String snapshotId;
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
