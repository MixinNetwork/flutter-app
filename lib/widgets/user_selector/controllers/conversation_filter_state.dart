part of 'conversation_filter_controller.dart';

class ConversationFilterState extends Equatable {
  const ConversationFilterState({
    this.recentConversations = const [],
    this.friends = const [],
    this.bots = const [],
    this.keyword,
    this.initialized = false,
  });

  final List<ConversationItem> recentConversations;
  final List<User> friends;
  final List<User> bots;
  final String? keyword;
  final bool initialized;

  Set<String> get appIds => {
    ...recentConversations.map((e) => e.ownerId).nonNulls,
    ...[...bots, ...friends].map((e) => e.userId),
  };

  @override
  List<Object?> get props => [
    friends,
    bots,
    keyword,
    recentConversations,
    initialized,
  ];

  ConversationFilterState copyWith({
    List<ConversationItem>? recentConversations,
    List<User>? friends,
    List<User>? bots,
    String? keyword,
    bool? initialized,
  }) => ConversationFilterState(
    recentConversations: recentConversations ?? this.recentConversations,
    friends: friends ?? this.friends,
    bots: bots ?? this.bots,
    keyword: keyword ?? this.keyword,
    initialized: initialized ?? this.initialized,
  );
}
