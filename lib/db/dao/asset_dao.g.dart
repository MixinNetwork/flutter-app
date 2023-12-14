// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetDaoMixin on DatabaseAccessor<MixinDatabase> {
  Assets get assets => attachedDatabase.assets;
  Chains get chains => attachedDatabase.chains;
  AddressesTable get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
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
  Tokens get tokens => attachedDatabase.tokens;
  Selectable<AssetItem> assetItem(String assetId) {
    return customSelect(
        'SELECT asset.*, chain.symbol AS chainSymbol, chain.icon_url AS chainIconUrl, chain.name AS chainName, chain.threshold AS chainThreshold FROM assets AS asset LEFT JOIN chains AS chain ON asset.chain_id = chain.chain_id WHERE asset.asset_id = ?1 LIMIT 1',
        variables: [
          Variable<String>(assetId)
        ],
        readsFrom: {
          chains,
          assets,
        }).map((QueryRow row) => AssetItem(
          assetId: row.read<String>('asset_id'),
          symbol: row.read<String>('symbol'),
          name: row.read<String>('name'),
          iconUrl: row.read<String>('icon_url'),
          balance: row.read<String>('balance'),
          destination: row.read<String>('destination'),
          tag: row.readNullable<String>('tag'),
          priceBtc: row.read<String>('price_btc'),
          priceUsd: row.read<String>('price_usd'),
          chainId: row.read<String>('chain_id'),
          changeUsd: row.read<String>('change_usd'),
          changeBtc: row.read<String>('change_btc'),
          confirmations: row.read<int>('confirmations'),
          assetKey: row.readNullable<String>('asset_key'),
          reserve: row.readNullable<String>('reserve'),
          chainSymbol: row.readNullable<String>('chainSymbol'),
          chainIconUrl: row.readNullable<String>('chainIconUrl'),
          chainName: row.readNullable<String>('chainName'),
          chainThreshold: row.readNullable<int>('chainThreshold'),
        ));
  }

  Selectable<int> countAssets() {
    return customSelect('SELECT COUNT(1) AS _c0 FROM assets',
        variables: [],
        readsFrom: {
          assets,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }
}

class AssetItem {
  final String assetId;
  final String symbol;
  final String name;
  final String iconUrl;
  final String balance;
  final String destination;
  final String? tag;
  final String priceBtc;
  final String priceUsd;
  final String chainId;
  final String changeUsd;
  final String changeBtc;
  final int confirmations;
  final String? assetKey;
  final String? reserve;
  final String? chainSymbol;
  final String? chainIconUrl;
  final String? chainName;
  final int? chainThreshold;
  AssetItem({
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.iconUrl,
    required this.balance,
    required this.destination,
    this.tag,
    required this.priceBtc,
    required this.priceUsd,
    required this.chainId,
    required this.changeUsd,
    required this.changeBtc,
    required this.confirmations,
    this.assetKey,
    this.reserve,
    this.chainSymbol,
    this.chainIconUrl,
    this.chainName,
    this.chainThreshold,
  });
  @override
  int get hashCode => Object.hash(
      assetId,
      symbol,
      name,
      iconUrl,
      balance,
      destination,
      tag,
      priceBtc,
      priceUsd,
      chainId,
      changeUsd,
      changeBtc,
      confirmations,
      assetKey,
      reserve,
      chainSymbol,
      chainIconUrl,
      chainName,
      chainThreshold);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetItem &&
          other.assetId == this.assetId &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.iconUrl == this.iconUrl &&
          other.balance == this.balance &&
          other.destination == this.destination &&
          other.tag == this.tag &&
          other.priceBtc == this.priceBtc &&
          other.priceUsd == this.priceUsd &&
          other.chainId == this.chainId &&
          other.changeUsd == this.changeUsd &&
          other.changeBtc == this.changeBtc &&
          other.confirmations == this.confirmations &&
          other.assetKey == this.assetKey &&
          other.reserve == this.reserve &&
          other.chainSymbol == this.chainSymbol &&
          other.chainIconUrl == this.chainIconUrl &&
          other.chainName == this.chainName &&
          other.chainThreshold == this.chainThreshold);
  @override
  String toString() {
    return (StringBuffer('AssetItem(')
          ..write('assetId: $assetId, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('balance: $balance, ')
          ..write('destination: $destination, ')
          ..write('tag: $tag, ')
          ..write('priceBtc: $priceBtc, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('chainId: $chainId, ')
          ..write('changeUsd: $changeUsd, ')
          ..write('changeBtc: $changeBtc, ')
          ..write('confirmations: $confirmations, ')
          ..write('assetKey: $assetKey, ')
          ..write('reserve: $reserve, ')
          ..write('chainSymbol: $chainSymbol, ')
          ..write('chainIconUrl: $chainIconUrl, ')
          ..write('chainName: $chainName, ')
          ..write('chainThreshold: $chainThreshold')
          ..write(')'))
        .toString();
  }
}
