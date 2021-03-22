part of 'forward_cubit.dart';

class ForwardState extends Equatable {
  const ForwardState({
    this.recentConversations = const [],
    this.friends = const [],
    this.bots = const [],
    this.keyword,
  });

  final List<ConversationItem> recentConversations;
  final List<User> friends;
  final List<User> bots;
  final String? keyword;

  @override
  List<Object?> get props => [
        friends,
        bots,
        keyword,
      ];

  ForwardState copyWith({
    List<ConversationItem>? recentConversations,
    List<User>? friends,
    List<User>? bots,
    String? keyword,
  }) {
    return ForwardState(
      recentConversations: recentConversations ?? this.recentConversations,
      friends: friends ?? this.friends,
      bots: bots ?? this.bots,
      keyword: keyword ?? this.keyword,
    );
  }
}
