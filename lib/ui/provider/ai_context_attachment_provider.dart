import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/mixin_database.dart';
import 'conversation_provider.dart';

class AiContextAttachmentNotifier extends StateNotifier<List<MessageItem>> {
  AiContextAttachmentNotifier(this.conversationId) : super(const []);

  final String conversationId;

  void attachMessages(Iterable<MessageItem> messages) {
    final next = {
      for (final message in state) message.messageId: message,
    };
    for (final message in messages) {
      if (message.conversationId != conversationId) {
        continue;
      }
      next[message.messageId] = message;
    }
    state = next.values.toList(growable: false)
      ..sort((a, b) {
        final result = a.createdAt.compareTo(b.createdAt);
        if (result != 0) return result;
        return a.messageId.compareTo(b.messageId);
      });
  }

  void remove(String messageId) {
    state = state
        .where((message) => message.messageId != messageId)
        .toList(growable: false);
  }

  void clear() {
    if (state.isEmpty) return;
    state = const [];
  }
}

final aiContextAttachmentProvider = StateNotifierProvider.autoDispose
    .family<AiContextAttachmentNotifier, List<MessageItem>, String>(
      (ref, conversationId) {
        final keepAlive = ref.keepAlive();
        ref.listen(currentConversationIdProvider, (previous, next) {
          if (next == conversationId) {
            return;
          }
          keepAlive.close();
          ref.invalidateSelf();
        });
        return AiContextAttachmentNotifier(conversationId);
      },
    );
