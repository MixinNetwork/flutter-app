// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sticker_dao.dart';

// ignore_for_file: type=lint
mixin _$StickerDaoMixin on DatabaseAccessor<MixinDatabase> {
  Stickers get stickers => attachedDatabase.stickers;
  StickerAlbums get stickerAlbums => attachedDatabase.stickerAlbums;
  StickerRelationships get stickerRelationships =>
      attachedDatabase.stickerRelationships;
  AddressesTable get addresses => attachedDatabase.addresses;
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
  Users get users => attachedDatabase.users;
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  Selectable<Sticker> recentUsedStickers() {
    return customSelect(
        'SELECT * FROM stickers WHERE last_use_at > 0 ORDER BY last_use_at DESC LIMIT 20',
        variables: [],
        readsFrom: {
          stickers,
        }).asyncMap(stickers.mapFromRow);
  }

  Selectable<Sticker> _stickersByCategory(String category) {
    return customSelect(
        'SELECT s.* FROM sticker_albums AS sa INNER JOIN sticker_relationships AS sr ON sr.album_id = sa.album_id INNER JOIN stickers AS s ON sr.sticker_id = s.sticker_id WHERE sa.category = ?1 ORDER BY s.created_at DESC',
        variables: [
          Variable<String>(category)
        ],
        readsFrom: {
          stickerAlbums,
          stickerRelationships,
          stickers,
        }).asyncMap(stickers.mapFromRow);
  }

  Selectable<int> countStickers() {
    return customSelect('SELECT COUNT(1) AS _c0 FROM stickers',
        variables: [],
        readsFrom: {
          stickers,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }
}
