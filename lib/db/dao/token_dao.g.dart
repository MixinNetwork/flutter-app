// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_dao.dart';

// ignore_for_file: type=lint
mixin _$TokenDaoMixin on DatabaseAccessor<MixinDatabase> {
  Tokens get tokens => attachedDatabase.tokens;
  TokensExtra get tokensExtra => attachedDatabase.tokensExtra;
  Chains get chains => attachedDatabase.chains;
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
  Users get users => attachedDatabase.users;
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Selectable<int> countAssets() {
    return customSelect(
      'SELECT COUNT(1) AS _c0 FROM tokens',
      variables: [],
      readsFrom: {this.tokens},
    ).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<WalletTokenItem> walletTokens(WalletTokens$where where) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
      where(
        alias(this.tokens, 't'),
        alias(this.tokensExtra, 'e'),
        alias(this.chains, 'c'),
      ),
      hasMultipleTables: true,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedwhere.amountOfVariables;
    return customSelect(
      'SELECT t.asset_id, t.kernel_asset_id, t.symbol, t.name, t.icon_url, t.price_usd, t.change_usd, t.chain_id, t.confirmations, t.dust, c.icon_url AS chain_icon_url, c.name AS chain_name, COALESCE(e.balance, \'0\') AS balance, COALESCE(e.hidden, FALSE) AS hidden FROM tokens AS t LEFT JOIN tokens_extra AS e ON e.kernel_asset_id = t.kernel_asset_id LEFT JOIN chains AS c ON c.chain_id = t.chain_id WHERE ${generatedwhere.sql} ORDER BY CAST(e.balance AS REAL) * CAST(t.price_usd AS REAL) DESC, CAST(e.balance AS REAL) DESC, t.name ASC',
      variables: [...generatedwhere.introducedVariables],
      readsFrom: {
        this.tokens,
        this.chains,
        this.tokensExtra,
        ...generatedwhere.watchedTables,
      },
    ).map(
      (QueryRow row) => WalletTokenItem(
        assetId: row.read<String>('asset_id'),
        kernelAssetId: row.read<String>('kernel_asset_id'),
        symbol: row.read<String>('symbol'),
        name: row.read<String>('name'),
        iconUrl: row.read<String>('icon_url'),
        priceUsd: row.read<String>('price_usd'),
        changeUsd: row.read<String>('change_usd'),
        chainId: row.read<String>('chain_id'),
        confirmations: row.read<int>('confirmations'),
        dust: row.read<String>('dust'),
        chainIconUrl: row.readNullable<String>('chain_icon_url'),
        chainName: row.readNullable<String>('chain_name'),
        balance: row.read<String>('balance'),
        hidden: row.read<bool>('hidden'),
      ),
    );
  }

  TokenDaoManager get managers => TokenDaoManager(this);
}

class TokenDaoManager {
  final _$TokenDaoMixin _db;
  TokenDaoManager(this._db);
  $TokensTableManager get tokens =>
      $TokensTableManager(_db.attachedDatabase, _db.tokens);
  $TokensExtraTableManager get tokensExtra =>
      $TokensExtraTableManager(_db.attachedDatabase, _db.tokensExtra);
  $ChainsTableManager get chains =>
      $ChainsTableManager(_db.attachedDatabase, _db.chains);
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
  $UsersTableManager get users =>
      $UsersTableManager(_db.attachedDatabase, _db.users);
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
  $PropertiesTableManager get properties =>
      $PropertiesTableManager(_db.attachedDatabase, _db.properties);
  $SafeSnapshotsTableManager get safeSnapshots =>
      $SafeSnapshotsTableManager(_db.attachedDatabase, _db.safeSnapshots);
  $InscriptionCollectionsTableManager get inscriptionCollections =>
      $InscriptionCollectionsTableManager(
        _db.attachedDatabase,
        _db.inscriptionCollections,
      );
  $InscriptionItemsTableManager get inscriptionItems =>
      $InscriptionItemsTableManager(_db.attachedDatabase, _db.inscriptionItems);
}

class WalletTokenItem {
  final String assetId;
  final String kernelAssetId;
  final String symbol;
  final String name;
  final String iconUrl;
  final String priceUsd;
  final String changeUsd;
  final String chainId;
  final int confirmations;
  final String dust;
  final String? chainIconUrl;
  final String? chainName;
  final String balance;
  final bool hidden;
  WalletTokenItem({
    required this.assetId,
    required this.kernelAssetId,
    required this.symbol,
    required this.name,
    required this.iconUrl,
    required this.priceUsd,
    required this.changeUsd,
    required this.chainId,
    required this.confirmations,
    required this.dust,
    this.chainIconUrl,
    this.chainName,
    required this.balance,
    required this.hidden,
  });
  @override
  int get hashCode => Object.hash(
    assetId,
    kernelAssetId,
    symbol,
    name,
    iconUrl,
    priceUsd,
    changeUsd,
    chainId,
    confirmations,
    dust,
    chainIconUrl,
    chainName,
    balance,
    hidden,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletTokenItem &&
          other.assetId == this.assetId &&
          other.kernelAssetId == this.kernelAssetId &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.iconUrl == this.iconUrl &&
          other.priceUsd == this.priceUsd &&
          other.changeUsd == this.changeUsd &&
          other.chainId == this.chainId &&
          other.confirmations == this.confirmations &&
          other.dust == this.dust &&
          other.chainIconUrl == this.chainIconUrl &&
          other.chainName == this.chainName &&
          other.balance == this.balance &&
          other.hidden == this.hidden);
  @override
  String toString() {
    return (StringBuffer('WalletTokenItem(')
          ..write('assetId: $assetId, ')
          ..write('kernelAssetId: $kernelAssetId, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('changeUsd: $changeUsd, ')
          ..write('chainId: $chainId, ')
          ..write('confirmations: $confirmations, ')
          ..write('dust: $dust, ')
          ..write('chainIconUrl: $chainIconUrl, ')
          ..write('chainName: $chainName, ')
          ..write('balance: $balance, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }
}

typedef WalletTokens$where =
    Expression<bool> Function(Tokens t, TokensExtra e, Chains c);
