// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sticker_relationship_dao.dart';

// ignore_for_file: type=lint
mixin _$StickerRelationshipDaoMixin on DatabaseAccessor<MixinDatabase> {
  StickerRelationships get stickerRelationships =>
      attachedDatabase.stickerRelationships;
  StickerAlbums get stickerAlbums => attachedDatabase.stickerAlbums;
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
  Stickers get stickers => attachedDatabase.stickers;
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
  Selectable<String> stickerSystemAlbumId(String stickerId) {
    return customSelect(
        'SELECT sa.album_id FROM sticker_relationships AS sr INNER JOIN sticker_albums AS sa ON sr.album_id = sa.album_id WHERE sr.sticker_id = ?1 AND sa.category = \'SYSTEM\' LIMIT 1',
        variables: [
          Variable<String>(stickerId)
        ],
        readsFrom: {
          stickerAlbums,
          stickerRelationships,
        }).map((QueryRow row) => row.read<String>('album_id'));
  }

  Selectable<StickerAlbum> stickerSystemAlbum(String stickerId) {
    return customSelect(
        'SELECT sa.* FROM sticker_relationships AS sr INNER JOIN sticker_albums AS sa ON sr.album_id = sa.album_id WHERE sr.sticker_id = ?1 AND sa.category = \'SYSTEM\' LIMIT 1',
        variables: [
          Variable<String>(stickerId)
        ],
        readsFrom: {
          stickerRelationships,
          stickerAlbums,
        }).asyncMap(stickerAlbums.mapFromRow);
  }
}
