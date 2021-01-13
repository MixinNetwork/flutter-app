part of 'message_bloc.dart';

class MessageState extends Equatable {
  const MessageState({
    this.messages,
    this.noMoreData = false,
    this.conversation,
  });

  final List<Message> messages;
  final bool noMoreData;
  final Conversation conversation;

  @override
  List<Object> get props => [messages, noMoreData];

  MessageState copyWith({
    final List<Message> messages,
    final bool noMoreData,
    final ConversationItemsResult conversation,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      noMoreData: noMoreData ?? this.noMoreData,
      conversation: conversation ?? this.conversation,
    );
  }
}
