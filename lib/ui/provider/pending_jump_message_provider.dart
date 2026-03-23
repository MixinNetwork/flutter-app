import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';

import 'conversation_provider.dart';

class PendingJumpMessageNotifier extends Notifier<String?> {
  KeepAliveLink? _keepAlive;

  @override
  String? build() {
    ref.listen(currentConversationIdProvider, (previous, next) {
      _keepAlive?.close();
      _keepAlive = null;
      state = null;
    });
    return null;
  }

  void set(String? value) {
    if (value == null) {
      _keepAlive?.close();
      _keepAlive = null;
    } else {
      _keepAlive ??= ref.keepAlive();
    }
    state = value;
  }

  void clear() => set(null);
}

final pendingJumpMessageProvider =
    NotifierProvider.autoDispose<PendingJumpMessageNotifier, String?>(
      PendingJumpMessageNotifier.new,
    );
