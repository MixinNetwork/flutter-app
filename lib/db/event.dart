import 'package:equatable/equatable.dart';

class MiniNotificationMessage with EquatableMixin {
  MiniNotificationMessage({
    required this.conversationId,
    required this.messageId,
    this.senderId,
    this.createdAt,
    required this.type,
  });

  final String conversationId;
  final String messageId;
  final String? senderId;
  final DateTime? createdAt;
  final String type;

  @override
  List<Object?> get props => [
        conversationId,
        messageId,
        senderId,
        createdAt,
        type,
      ];
}

class MiniSticker with EquatableMixin {
  MiniSticker({
    this.stickerId,
    this.albumId,
  });

  final String? stickerId;
  final String? albumId;

  @override
  List<Object?> get props => [stickerId, albumId];
}
