import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:rxdart/rxdart.dart';

import '../../account/account_server.dart';
import '../../db/dao/conversation_dao.dart';
import '../../db/database.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../enum/encrypt_category.dart';
import '../../utils/app_lifecycle.dart';
import '../../utils/extension/extension.dart';
import '../../utils/local_notification_center.dart';
import '../../utils/rivepod.dart';
import '../home/conversation_info_destination.dart';
import '../home/notifier/subscriber_mixin.dart';
import 'account_server_provider.dart';
import 'major_navigation_provider.dart';

class ConversationState extends Equatable {
  const ConversationState({
    required this.conversationId,
    required this.refreshKey,
    this.userId,
    this.initIndexMessageId,
    this.lastReadMessageId,
    this.conversation,
    this.user,
    this.app,
    this.participant,
    this.initialSidePage,
    this.keyword,
    this.forceLatestKey,
  });

  final String conversationId;
  final String? userId;
  final String? initIndexMessageId;
  final String? lastReadMessageId;
  final ConversationItem? conversation;
  final User? user;
  final App? app;
  final Participant? participant;
  final Object refreshKey;

  final ConversationInfoDestination? initialSidePage;
  final String? keyword;
  final Object? forceLatestKey;

  bool get isLoaded => conversation != null || user != null;

  bool get isBot => conversation?.isBotConversation ?? user?.isBot ?? false;

  bool get isVerified =>
      conversation?.ownerVerified ?? user?.isVerified ?? false;

  Membership? get membership => user?.membership ?? conversation?.membership;

  // note: check user information first.
  // because in bot stranger conversation. it might be conversation.isStrangerConversation == false
  bool? get isStranger =>
      user?.isStranger ?? conversation?.isStrangerConversation;

  bool? get isGroup =>
      conversation?.isGroupConversation ?? (user != null ? false : null);

  String? get name => conversation?.validName ?? user?.fullName;

  String? get identityNumber =>
      conversation?.ownerIdentityNumber ?? user?.identityNumber;

  UserRelationship? get relationship =>
      conversation?.relationship ?? user?.relationship;

  EncryptCategory get encryptCategory => _getEncryptCategory(app);

  ParticipantRole? get role =>
      conversation?.category == ConversationCategory.contact
      ? ParticipantRole.owner
      : participant?.role;

  @override
  List<Object?> get props => [
    conversationId,
    userId,
    initIndexMessageId,
    conversation,
    user,
    lastReadMessageId,
    refreshKey,
    initialSidePage,
    participant,
    keyword,
    forceLatestKey,
  ];

  ConversationState copyWith({
    String? conversationId,
    String? userId,
    String? initIndexMessageId,
    String? lastReadMessageId,
    ConversationItem? conversation,
    User? user,
    App? app,
    Participant? participant,
    Object? refreshKey,
    ConversationInfoDestination? initialSidePage,
    String? keyword,
    Object? forceLatestKey,
  }) => ConversationState(
    conversationId: conversationId ?? this.conversationId,
    userId: userId ?? this.userId,
    initIndexMessageId: initIndexMessageId ?? this.initIndexMessageId,
    conversation: conversation ?? this.conversation,
    user: user ?? this.user,
    app: app ?? this.app,
    lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
    refreshKey: refreshKey ?? this.refreshKey,
    initialSidePage: initialSidePage ?? this.initialSidePage,
    participant: participant ?? this.participant,
    keyword: keyword ?? this.keyword,
    forceLatestKey: forceLatestKey ?? this.forceLatestKey,
  );
}

EncryptCategory _getEncryptCategory(App? app) {
  if (app != null && app.capabilities?.contains('ENCRYPTED') == true) {
    return EncryptCategory.encrypted;
  } else if (app != null) {
    return EncryptCategory.plain;
  }
  return EncryptCategory.signal;
}

class ConversationStateNotifier
    extends DistinctStateNotifier<ConversationState?>
    with SubscriberMixin {
  ConversationStateNotifier({
    required AccountServer accountServer,
    required MajorNavigationNotifier majorNavigationNotifier,
  }) : _majorNavigationNotifier = majorNavigationNotifier,
       _accountServer = accountServer,
       super(null) {
    addSubscription(
      stream
          .map((event) => event?.conversationId)
          .distinct()
          .listen(_accountServer.selectConversation),
    );
    addSubscription(
      stream
          .map((event) => (event?.conversationId, event?.userId))
          .where((event) => event.$1 != null)
          .distinct()
          .switchMap((event) {
            final (String? conversationId, String? userId) = event;
            return _database.conversationDao
                .conversationItem(conversationId!)
                .watchSingleOrNullWithStream(
                  eventStreams: [
                    DataBaseEventBus.instance.watchUpdateConversationStream([
                      conversationId,
                    ]),
                    if (userId != null)
                      DataBaseEventBus.instance.watchUpdateUserStream([userId]),
                  ],
                  duration: kSlowThrottleDuration,
                  prepend: false,
                );
          })
          .listen((event) {
            String? userId;
            if (event != null && !event.isGroupConversation) {
              userId = event.ownerId;
            }
            state = state?.copyWith(conversation: event, userId: userId);
          }),
    );
    addSubscription(
      stream
          .map((event) => event?.userId)
          .distinct()
          .switchMap((userId) {
            if (userId == null) return Stream.value(null);
            return _database.userDao
                .userById(userId)
                .watchSingleOrNullWithStream(
                  eventStreams: [
                    DataBaseEventBus.instance.watchUpdateUserStream([userId]),
                  ],
                  duration: kDefaultThrottleDuration,
                  prepend: false,
                );
          })
          .listen((event) => state = state?.copyWith(user: event)),
    );
    addSubscription(
      stream
          .map((event) => event?.conversationId)
          .where((event) => event != null)
          .distinct()
          .switchMap(
            (conversationId) => _database.participantDao
                .participantById(conversationId!, _currentUserId)
                .watchSingleOrNullWithStream(
                  eventStreams: [
                    DataBaseEventBus.instance.watchUpdateParticipantStream(
                      conversationIds: [conversationId],
                      userIds: [_currentUserId],
                      and: true,
                    ),
                  ],
                  duration: kSlowThrottleDuration,
                  prepend: false,
                ),
          )
          .listen((event) {
            state = state?.copyWith(participant: event);
          }),
    );

    appActiveListener.addListener(onListen);
  }

  final AccountServer _accountServer;
  final MajorNavigationNotifier _majorNavigationNotifier;
  late final Database _database = _accountServer.database;
  late final String _currentUserId = _accountServer.userId;

  @override
  void dispose() {
    appActiveListener.removeListener(onListen);
    super.dispose();
  }

  void onListen() {
    if (isAppActive && state?.conversationId != null) {
      dismissByConversationId(state!.conversationId);
      return;
    }
  }

  void unselected() {
    state = null;
    _majorNavigationNotifier.clear();
  }

  void openChatPage() {
    _majorNavigationNotifier.openChatPage();
  }

  void openLatest() {
    state = state?.copyWith(forceLatestKey: Object());
    openChatPage();
  }

  void focus(ConversationState nextState) {
    state = nextState;
    openChatPage();
  }
}

class _LastConversationNotifier
    extends DistinctStateNotifier<ConversationState?> {
  _LastConversationNotifier(super.state);

  set _state(ConversationState? value) => super.state = value;
}

final conversationProvider =
    StateNotifierProvider.autoDispose<
      ConversationStateNotifier,
      ConversationState?
    >((ref) {
      final keepAlive = ref.keepAlive();

      final accountServerAsync = ref.watch(accountServerProvider);

      if (!accountServerAsync.hasValue) {
        throw Exception('accountServer is not ready');
      }

      final majorNavigationNotifier = ref.watch(
        majorNavigationProvider.notifier,
      );

      ref
        ..listen(accountServerProvider, (previous, next) => keepAlive.close())
        ..listen(
          majorNavigationProvider.notifier,
          (previous, next) => keepAlive.close(),
        );

      return ConversationStateNotifier(
        accountServer: accountServerAsync.requireValue,
        majorNavigationNotifier: majorNavigationNotifier,
      );
    });

final _lastConversationProvider =
    StateNotifierProvider.autoDispose<
      _LastConversationNotifier,
      ConversationState?
    >((ref) {
      final conversation = ref.read(conversationProvider);
      final lastConversationNotifier = _LastConversationNotifier(conversation);
      ref.listen(conversationProvider, (previous, next) {
        if (next == null) return;
        lastConversationNotifier._state = next;
      });
      return lastConversationNotifier;
    });

final filterLastConversationProvider = StateNotifierProvider.autoDispose
    .family<
      _LastConversationNotifier,
      ConversationState?,
      bool Function(ConversationState?)
    >((ref, filter) {
      final conversation = ref.read(conversationProvider);
      final lastConversationNotifier = _LastConversationNotifier(conversation);
      ref.listen(conversationProvider, (previous, next) {
        if (!filter(next)) return;
        lastConversationNotifier._state = next;
      });
      return lastConversationNotifier;
    });

final lastConversationProvider = _lastConversationProvider.select(
  (value) => value,
);

final lastConversationIdProvider = lastConversationProvider.select(
  (value) => value?.conversationId,
);

final currentConversationIdProvider = conversationProvider.select(
  (value) => value?.conversationId,
);

final currentConversationNameProvider = conversationProvider.select(
  (value) => value?.conversation?.name,
);

final currentConversationHasParticipantProvider = conversationProvider.select((
  value,
) {
  if (value?.conversation == null) return true;
  if (value?.conversation?.category == ConversationCategory.contact) {
    return true;
  }
  if (value?.conversation?.status == ConversationStatus.quit) {
    return false;
  }
  return value?.participant != null;
});
