// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'circle_conversation_dao.dart';

// ignore_for_file: type=lint
mixin _$CircleConversationDaoMixin on DatabaseAccessor<MixinDatabase> {
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
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
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Future<int> _deleteByCircleId(String circleId) {
    return customUpdate(
      'DELETE FROM circle_conversations WHERE circle_id = ?1',
      variables: [Variable<String>(circleId)],
      updates: {circleConversations},
      updateKind: UpdateKind.delete,
    );
  }

  Future<int> _deleteByIds(String conversationId, String circleId) {
    return customUpdate(
      'DELETE FROM circle_conversations WHERE conversation_id = ?1 AND circle_id = ?2',
      variables: [Variable<String>(conversationId), Variable<String>(circleId)],
      updates: {circleConversations},
      updateKind: UpdateKind.delete,
    );
  }
}
