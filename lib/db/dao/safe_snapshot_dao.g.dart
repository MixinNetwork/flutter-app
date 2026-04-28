// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safe_snapshot_dao.dart';

// ignore_for_file: type=lint
mixin _$SafeSnapshotDaoMixin on DatabaseAccessor<MixinDatabase> {
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Users get users => attachedDatabase.users;
  Tokens get tokens => attachedDatabase.tokens;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Circles get circles => attachedDatabase.circles;
  Conversations get conversations => attachedDatabase.conversations;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  Jobs get jobs => attachedDatabase.jobs;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
  Messages get messages => attachedDatabase.messages;
  MessagesHistory get messagesHistory => attachedDatabase.messagesHistory;
  Offsets get offsets => attachedDatabase.offsets;
  ParticipantSession get participantSession =>
      attachedDatabase.participantSession;
  Participants get participants => attachedDatabase.participants;
  ResendSessionMessages get resendSessionMessages =>
      attachedDatabase.resendSessionMessages;
  SentSessionSenderKeys get sentSessionSenderKeys =>
      attachedDatabase.sentSessionSenderKeys;
  Snapshots get snapshots => attachedDatabase.snapshots;
  StickerAlbums get stickerAlbums => attachedDatabase.stickerAlbums;
  StickerRelationships get stickerRelationships =>
      attachedDatabase.stickerRelationships;
  Stickers get stickers => attachedDatabase.stickers;
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Selectable<SafeSnapshotItem> _snapshotItem(
    SnapshotItem$where where,
    SnapshotItem$order order,
    SnapshotItem$limit limit,
  ) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
      where(
        alias(this.safeSnapshots, 's'),
        alias(this.users, 'u'),
        alias(this.tokens, 't'),
      ),
      hasMultipleTables: true,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedorder = $write(
      order?.call(
            alias(this.safeSnapshots, 's'),
            alias(this.users, 'u'),
            alias(this.tokens, 't'),
          ) ??
          const OrderBy.nothing(),
      hasMultipleTables: true,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
      limit(
        alias(this.safeSnapshots, 's'),
        alias(this.users, 'u'),
        alias(this.tokens, 't'),
      ),
      hasMultipleTables: true,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
      'SELECT s.snapshot_id, s.type, s.asset_id, s.amount, s.created_at, s.opponent_id, s.trace_id, s.memo, s.confirmations, s.transaction_hash, s.opening_balance, s.closing_balance, u.avatar_url, u.full_name AS opponent_ful_name, t.symbol AS asset_symbol, t.confirmations AS asset_confirmations FROM safe_snapshots AS s LEFT JOIN users AS u ON u.user_id = s.opponent_id LEFT JOIN tokens AS t ON t.asset_id = s.asset_id WHERE ${generatedwhere.sql} ${generatedorder.sql} ${generatedlimit.sql}',
      variables: [
        ...generatedwhere.introducedVariables,
        ...generatedorder.introducedVariables,
        ...generatedlimit.introducedVariables,
      ],
      readsFrom: {
        safeSnapshots,
        users,
        tokens,
        ...generatedwhere.watchedTables,
        ...generatedorder.watchedTables,
        ...generatedlimit.watchedTables,
      },
    ).map(
      (QueryRow row) => SafeSnapshotItem(
        snapshotId: row.read<String>('snapshot_id'),
        type: row.read<String>('type'),
        assetId: row.read<String>('asset_id'),
        amount: row.read<String>('amount'),
        createdAt: row.read<String>('created_at'),
        opponentId: row.read<String>('opponent_id'),
        traceId: row.readNullable<String>('trace_id'),
        memo: row.read<String>('memo'),
        confirmations: row.readNullable<int>('confirmations'),
        transactionHash: row.read<String>('transaction_hash'),
        openingBalance: row.readNullable<String>('opening_balance'),
        closingBalance: row.readNullable<String>('closing_balance'),
        avatarUrl: row.readNullable<String>('avatar_url'),
        opponentFulName: row.readNullable<String>('opponent_ful_name'),
        assetSymbol: row.readNullable<String>('asset_symbol'),
        assetConfirmations: row.readNullable<int>('asset_confirmations'),
      ),
    );
  }

  Future<int> deletePendingSnapshotByHash(String transactionHash) {
    return customUpdate(
      'DELETE FROM safe_snapshots WHERE type = \'pending\' AND deposit LIKE \'%\' || ?1 || \'%\' ESCAPE \'\\\'',
      variables: [Variable<String>(transactionHash)],
      updates: {safeSnapshots},
      updateKind: UpdateKind.delete,
    );
  }

  Selectable<int> countSnapshots() {
    return customSelect(
      'SELECT COUNT(1) AS _c0 FROM safe_snapshots',
      variables: [],
      readsFrom: {safeSnapshots},
    ).map((QueryRow row) => row.read<int>('_c0'));
  }

  SafeSnapshotDaoManager get managers => SafeSnapshotDaoManager(this);
}

class SafeSnapshotDaoManager {
  final _$SafeSnapshotDaoMixin _db;
  SafeSnapshotDaoManager(this._db);
  $SafeSnapshotsTableManager get safeSnapshots =>
      $SafeSnapshotsTableManager(_db.attachedDatabase, _db.safeSnapshots);
  $UsersTableManager get users =>
      $UsersTableManager(_db.attachedDatabase, _db.users);
  $TokensTableManager get tokens =>
      $TokensTableManager(_db.attachedDatabase, _db.tokens);
  $AddressesTableManager get addresses =>
      $AddressesTableManager(_db.attachedDatabase, _db.addresses);
  $AppsTableManager get apps =>
      $AppsTableManager(_db.attachedDatabase, _db.apps);
  $AssetsTableManager get assets =>
      $AssetsTableManager(_db.attachedDatabase, _db.assets);
  $CircleConversationsTableManager get circleConversations =>
      $CircleConversationsTableManager(
        _db.attachedDatabase,
        _db.circleConversations,
      );
  $CirclesTableManager get circles =>
      $CirclesTableManager(_db.attachedDatabase, _db.circles);
  $ConversationsTableManager get conversations =>
      $ConversationsTableManager(_db.attachedDatabase, _db.conversations);
  $FloodMessagesTableManager get floodMessages =>
      $FloodMessagesTableManager(_db.attachedDatabase, _db.floodMessages);
  $HyperlinksTableManager get hyperlinks =>
      $HyperlinksTableManager(_db.attachedDatabase, _db.hyperlinks);
  $JobsTableManager get jobs =>
      $JobsTableManager(_db.attachedDatabase, _db.jobs);
  $MessageMentionsTableManager get messageMentions =>
      $MessageMentionsTableManager(_db.attachedDatabase, _db.messageMentions);
  $MessagesTableManager get messages =>
      $MessagesTableManager(_db.attachedDatabase, _db.messages);
  $MessagesHistoryTableManager get messagesHistory =>
      $MessagesHistoryTableManager(_db.attachedDatabase, _db.messagesHistory);
  $OffsetsTableManager get offsets =>
      $OffsetsTableManager(_db.attachedDatabase, _db.offsets);
  $ParticipantSessionTableManager get participantSession =>
      $ParticipantSessionTableManager(
        _db.attachedDatabase,
        _db.participantSession,
      );
  $ParticipantsTableManager get participants =>
      $ParticipantsTableManager(_db.attachedDatabase, _db.participants);
  $ResendSessionMessagesTableManager get resendSessionMessages =>
      $ResendSessionMessagesTableManager(
        _db.attachedDatabase,
        _db.resendSessionMessages,
      );
  $SentSessionSenderKeysTableManager get sentSessionSenderKeys =>
      $SentSessionSenderKeysTableManager(
        _db.attachedDatabase,
        _db.sentSessionSenderKeys,
      );
  $SnapshotsTableManager get snapshots =>
      $SnapshotsTableManager(_db.attachedDatabase, _db.snapshots);
  $StickerAlbumsTableManager get stickerAlbums =>
      $StickerAlbumsTableManager(_db.attachedDatabase, _db.stickerAlbums);
  $StickerRelationshipsTableManager get stickerRelationships =>
      $StickerRelationshipsTableManager(
        _db.attachedDatabase,
        _db.stickerRelationships,
      );
  $StickersTableManager get stickers =>
      $StickersTableManager(_db.attachedDatabase, _db.stickers);
  $TranscriptMessagesTableManager get transcriptMessages =>
      $TranscriptMessagesTableManager(
        _db.attachedDatabase,
        _db.transcriptMessages,
      );
  $PinMessagesTableManager get pinMessages =>
      $PinMessagesTableManager(_db.attachedDatabase, _db.pinMessages);
  $FiatsTableManager get fiats =>
      $FiatsTableManager(_db.attachedDatabase, _db.fiats);
  $FavoriteAppsTableManager get favoriteApps =>
      $FavoriteAppsTableManager(_db.attachedDatabase, _db.favoriteApps);
  $ExpiredMessagesTableManager get expiredMessages =>
      $ExpiredMessagesTableManager(_db.attachedDatabase, _db.expiredMessages);
  $ChainsTableManager get chains =>
      $ChainsTableManager(_db.attachedDatabase, _db.chains);
  $PropertiesTableManager get properties =>
      $PropertiesTableManager(_db.attachedDatabase, _db.properties);
  $InscriptionCollectionsTableManager get inscriptionCollections =>
      $InscriptionCollectionsTableManager(
        _db.attachedDatabase,
        _db.inscriptionCollections,
      );
  $InscriptionItemsTableManager get inscriptionItems =>
      $InscriptionItemsTableManager(_db.attachedDatabase, _db.inscriptionItems);
}

class SafeSnapshotItem {
  final String snapshotId;
  final String type;
  final String assetId;
  final String amount;
  final String createdAt;
  final String opponentId;
  final String? traceId;
  final String memo;
  final int? confirmations;
  final String transactionHash;
  final String? openingBalance;
  final String? closingBalance;
  final String? avatarUrl;
  final String? opponentFulName;
  final String? assetSymbol;
  final int? assetConfirmations;
  SafeSnapshotItem({
    required this.snapshotId,
    required this.type,
    required this.assetId,
    required this.amount,
    required this.createdAt,
    required this.opponentId,
    this.traceId,
    required this.memo,
    this.confirmations,
    required this.transactionHash,
    this.openingBalance,
    this.closingBalance,
    this.avatarUrl,
    this.opponentFulName,
    this.assetSymbol,
    this.assetConfirmations,
  });
  @override
  int get hashCode => Object.hash(
    snapshotId,
    type,
    assetId,
    amount,
    createdAt,
    opponentId,
    traceId,
    memo,
    confirmations,
    transactionHash,
    openingBalance,
    closingBalance,
    avatarUrl,
    opponentFulName,
    assetSymbol,
    assetConfirmations,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SafeSnapshotItem &&
          other.snapshotId == this.snapshotId &&
          other.type == this.type &&
          other.assetId == this.assetId &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt &&
          other.opponentId == this.opponentId &&
          other.traceId == this.traceId &&
          other.memo == this.memo &&
          other.confirmations == this.confirmations &&
          other.transactionHash == this.transactionHash &&
          other.openingBalance == this.openingBalance &&
          other.closingBalance == this.closingBalance &&
          other.avatarUrl == this.avatarUrl &&
          other.opponentFulName == this.opponentFulName &&
          other.assetSymbol == this.assetSymbol &&
          other.assetConfirmations == this.assetConfirmations);
  @override
  String toString() {
    return (StringBuffer('SafeSnapshotItem(')
          ..write('snapshotId: $snapshotId, ')
          ..write('type: $type, ')
          ..write('assetId: $assetId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('opponentId: $opponentId, ')
          ..write('traceId: $traceId, ')
          ..write('memo: $memo, ')
          ..write('confirmations: $confirmations, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('closingBalance: $closingBalance, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('opponentFulName: $opponentFulName, ')
          ..write('assetSymbol: $assetSymbol, ')
          ..write('assetConfirmations: $assetConfirmations')
          ..write(')'))
        .toString();
  }
}

typedef SnapshotItem$where =
    Expression<bool> Function(SafeSnapshots s, Users u, Tokens t);
typedef SnapshotItem$order =
    OrderBy Function(SafeSnapshots s, Users u, Tokens t);
typedef SnapshotItem$limit = Limit Function(SafeSnapshots s, Users u, Tokens t);
