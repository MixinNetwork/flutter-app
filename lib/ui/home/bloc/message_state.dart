part of 'message_bloc.dart';

class MessageState extends Equatable {
  const MessageState({
    this.messages,
    this.noMoreData = false,
    this.conversationId,
  });

  final List<Message> messages;
  final bool noMoreData;
  final String conversationId;

  @override
  List<Object> get props => [messages, noMoreData];

  MessageState copyWith({
    final List<Message> messages,
    final bool noMoreData,
    final String conversationId,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      noMoreData: noMoreData ?? this.noMoreData,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}
