import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/rivepod.dart';
import 'multi_auth_provider.dart';

abstract class ConversationMenuHandle {
  Stream<bool> get isMuted;

  Stream<bool> get isPinned;

  void mute();

  void unmute();

  void showSearch();

  void pin();

  void unPin();

  void toggleSideBar();

  void delete();
}

class MacMenuBarStateNotifier
    extends DistinctStateNotifier<ConversationMenuHandle?> {
  MacMenuBarStateNotifier(super.state);

  void attach(ConversationMenuHandle handle) {
    if (!Platform.isMacOS) return;
    Future(() => state = handle);
  }

  void unAttach(ConversationMenuHandle handle) {
    if (!Platform.isMacOS) return;
    if (state != handle) return;
    state = null;
  }

  void _clear() {
    if (!Platform.isMacOS) return;
    state = null;
  }
}

final macMenuBarProvider =
    StateNotifierProvider<MacMenuBarStateNotifier, ConversationMenuHandle?>(
  (ref) {
    // clear state when account changed
    ref.listen(
      authAccountProvider.select((value) => value?.identityNumber),
      (previous, next) {
        if (previous != null && next != null) {
          ref.notifier._clear();
        }
      },
    );
    return MacMenuBarStateNotifier(null);
  },
);
