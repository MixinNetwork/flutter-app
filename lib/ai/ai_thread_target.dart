sealed class AiThreadTarget {
  const AiThreadTarget();

  const factory AiThreadTarget.existing(String threadId) =
      ExistingAiThreadTarget;

  const factory AiThreadTarget.createNew() = NewAiThreadTarget;
}

class ExistingAiThreadTarget extends AiThreadTarget {
  const ExistingAiThreadTarget(this.threadId);

  final String threadId;
}

class NewAiThreadTarget extends AiThreadTarget {
  const NewAiThreadTarget();
}
