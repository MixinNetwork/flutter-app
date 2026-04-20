import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ai/model/ai_mode_state.dart';

class AiInputModeNotifier extends StateNotifier<AiModeState> {
  AiInputModeNotifier() : super(const AiModeState());

  void enter({String? providerId}) {
    state = AiModeState(enabled: true, providerId: providerId);
  }

  void exit() {
    state = const AiModeState();
  }
}

final aiInputModeProvider = StateNotifierProvider.autoDispose
    .family<AiInputModeNotifier, AiModeState, String>(
      (ref, _) => AiInputModeNotifier(),
    );
