import 'package:hooks_riverpod/hooks_riverpod.dart';

enum AiAssistantThreadSelectionType { latest, newThread, existing }

class AiAssistantThreadSelection {
  const AiAssistantThreadSelection._(this.type, this.threadId);

  const AiAssistantThreadSelection.latest()
    : this._(AiAssistantThreadSelectionType.latest, null);

  const AiAssistantThreadSelection.newThread()
    : this._(AiAssistantThreadSelectionType.newThread, null);

  const AiAssistantThreadSelection.existing(String threadId)
    : this._(AiAssistantThreadSelectionType.existing, threadId);

  final AiAssistantThreadSelectionType type;
  final String? threadId;

  bool get isLatest => type == AiAssistantThreadSelectionType.latest;
  bool get isNewThread => type == AiAssistantThreadSelectionType.newThread;
}

final aiAssistantThreadSelectionProvider = StateProvider.autoDispose
    .family<AiAssistantThreadSelection, String>(
      (ref, conversationId) => const AiAssistantThreadSelection.latest(),
    );
