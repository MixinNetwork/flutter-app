// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_app_dao.dart';

// ignore_for_file: type=lint
mixin _$FavoriteAppDaoMixin on DatabaseAccessor<MixinDatabase> {
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  Apps get apps => attachedDatabase.apps;
  AddressesTable get addresses => attachedDatabase.addresses;
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
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Future<int> _deleteFavoriteAppByUserId(String userId) {
    return customUpdate(
      'DELETE FROM favorite_apps WHERE user_id = ?1',
      variables: [Variable<String>(userId)],
      updates: {favoriteApps},
      updateKind: UpdateKind.delete,
    );
  }

  Selectable<App> getFavoriteAppsByUserId(String userId) {
    return customSelect(
        'SELECT a.* FROM favorite_apps AS fa INNER JOIN apps AS a ON fa.app_id = a.app_id WHERE fa.user_id = ?1',
        variables: [
          Variable<String>(userId)
        ],
        readsFrom: {
          favoriteApps,
          apps,
        }).asyncMap(apps.mapFromRow);
  }
}
