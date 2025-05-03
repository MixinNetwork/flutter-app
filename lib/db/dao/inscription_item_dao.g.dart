// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inscription_item_dao.dart';

// ignore_for_file: type=lint
mixin _$InscriptionItemDaoMixin on DatabaseAccessor<MixinDatabase> {
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
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
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  Selectable<Inscription> inscriptionByHash(String hash) {
    return customSelect(
      'SELECT i.collection_hash, i.inscription_hash, ic.name, i.sequence, i.content_type, i.content_url, ic.icon_url FROM inscription_items AS i LEFT JOIN inscription_collections AS ic ON ic.collection_hash = i.collection_hash WHERE inscription_hash = ?1',
      variables: [Variable<String>(hash)],
      readsFrom: {inscriptionItems, inscriptionCollections},
    ).map(
      (QueryRow row) => Inscription(
        collectionHash: row.read<String>('collection_hash'),
        inscriptionHash: row.read<String>('inscription_hash'),
        sequence: row.read<int>('sequence'),
        contentType: row.read<String>('content_type'),
        contentUrl: row.read<String>('content_url'),
        name: row.readNullable<String>('name'),
        iconUrl: row.readNullable<String>('icon_url'),
      ),
    );
  }
}
