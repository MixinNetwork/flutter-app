// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'circle_dao.dart';

// ignore_for_file: type=lint
mixin _$CircleDaoMixin on DatabaseAccessor<MixinDatabase> {
  Circles get circles => attachedDatabase.circles;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Conversations get conversations => attachedDatabase.conversations;
  Users get users => attachedDatabase.users;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
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
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  Selectable<ConversationCircleItem> allCircles() {
    return customSelect(
        'SELECT ci.circle_id, ci.name, ci.created_at, ci.ordered_at, COUNT(c.conversation_id) AS count, IFNULL(SUM(CASE WHEN IFNULL(c.unseen_message_count, 0) > 0 THEN 1 ELSE 0 END), 0) AS unseen_conversation_count, IFNULL(SUM(CASE WHEN(CASE WHEN c.category = \'GROUP\' THEN c.mute_until ELSE owner.mute_until END)>=(strftime(\'%s\', \'now\') * 1000)AND IFNULL(c.unseen_message_count, 0) > 0 THEN 1 ELSE 0 END), 0) AS unseen_muted_conversation_count FROM circles AS ci LEFT JOIN circle_conversations AS cc ON ci.circle_id = cc.circle_id LEFT JOIN conversations AS c ON c.conversation_id = cc.conversation_id LEFT JOIN users AS owner ON owner.user_id = c.owner_id GROUP BY ci.circle_id ORDER BY ci.ordered_at ASC, ci.created_at ASC',
        variables: [],
        readsFrom: {
          circles,
          conversations,
          users,
          circleConversations,
        }).map((QueryRow row) => ConversationCircleItem(
          circleId: row.read<String>('circle_id'),
          name: row.read<String>('name'),
          createdAt:
              Circles.$convertercreatedAt.fromSql(row.read<int>('created_at')),
          orderedAt: NullAwareTypeConverter.wrapFromSql(
              Circles.$converterorderedAt, row.readNullable<int>('ordered_at')),
          count: row.read<int>('count'),
          unseenConversationCount: row.read<int>('unseen_conversation_count'),
          unseenMutedConversationCount:
              row.read<int>('unseen_muted_conversation_count'),
        ));
  }

  Selectable<ConversationCircleManagerItem> circleByConversationId(
      String? conversationId) {
    return customSelect(
        'SELECT ci.circle_id, ci.name, COUNT(c.conversation_id) AS count FROM circles AS ci LEFT JOIN circle_conversations AS cc ON ci.circle_id = cc.circle_id LEFT JOIN conversations AS c ON c.conversation_id = cc.conversation_id WHERE ci.circle_id IN (SELECT cir.circle_id FROM circles AS cir LEFT JOIN circle_conversations AS ccr ON cir.circle_id = ccr.circle_id WHERE ccr.conversation_id = ?1) GROUP BY ci.circle_id ORDER BY ci.ordered_at ASC, ci.created_at ASC',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          circles,
          conversations,
          circleConversations,
        }).map((QueryRow row) => ConversationCircleManagerItem(
          circleId: row.read<String>('circle_id'),
          name: row.read<String>('name'),
          count: row.read<int>('count'),
        ));
  }

  Selectable<ConversationCircleManagerItem> otherCircleByConversationId(
      String? conversationId) {
    return customSelect(
        'SELECT ci.circle_id, ci.name, COUNT(c.conversation_id) AS count FROM circles AS ci LEFT JOIN circle_conversations AS cc ON ci.circle_id = cc.circle_id LEFT JOIN conversations AS c ON c.conversation_id = cc.conversation_id WHERE ci.circle_id NOT IN (SELECT cir.circle_id FROM circles AS cir LEFT JOIN circle_conversations AS ccr ON cir.circle_id = ccr.circle_id WHERE ccr.conversation_id = ?1) GROUP BY ci.circle_id ORDER BY ci.ordered_at ASC, ci.created_at ASC',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          circles,
          conversations,
          circleConversations,
        }).map((QueryRow row) => ConversationCircleManagerItem(
          circleId: row.read<String>('circle_id'),
          name: row.read<String>('name'),
          count: row.read<int>('count'),
        ));
  }
}

class ConversationCircleItem {
  final String circleId;
  final String name;
  final DateTime createdAt;
  final DateTime? orderedAt;
  final int count;
  final int unseenConversationCount;
  final int unseenMutedConversationCount;
  ConversationCircleItem({
    required this.circleId,
    required this.name,
    required this.createdAt,
    this.orderedAt,
    required this.count,
    required this.unseenConversationCount,
    required this.unseenMutedConversationCount,
  });
  @override
  int get hashCode => Object.hash(circleId, name, createdAt, orderedAt, count,
      unseenConversationCount, unseenMutedConversationCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationCircleItem &&
          other.circleId == this.circleId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.orderedAt == this.orderedAt &&
          other.count == this.count &&
          other.unseenConversationCount == this.unseenConversationCount &&
          other.unseenMutedConversationCount ==
              this.unseenMutedConversationCount);
  @override
  String toString() {
    return (StringBuffer('ConversationCircleItem(')
          ..write('circleId: $circleId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderedAt: $orderedAt, ')
          ..write('count: $count, ')
          ..write('unseenConversationCount: $unseenConversationCount, ')
          ..write('unseenMutedConversationCount: $unseenMutedConversationCount')
          ..write(')'))
        .toString();
  }
}

class ConversationCircleManagerItem {
  final String circleId;
  final String name;
  final int count;
  ConversationCircleManagerItem({
    required this.circleId,
    required this.name,
    required this.count,
  });
  @override
  int get hashCode => Object.hash(circleId, name, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationCircleManagerItem &&
          other.circleId == this.circleId &&
          other.name == this.name &&
          other.count == this.count);
  @override
  String toString() {
    return (StringBuffer('ConversationCircleManagerItem(')
          ..write('circleId: $circleId, ')
          ..write('name: $name, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }
}
