import '../db/mixin_database.dart';

enum MainIsolateEventType {
  reconnectBlaze,
  disconnectBlazeWithTime,
  updateSelectedConversation,
  addAckJobs,
  addSessionAckJobs,
  addSendingJob,
  addUpdateAssetJob,
  addUpdateStickerJob,
  addUpdateTokenJob,
  addSyncInscriptionMessageJob,
  exit,
}

extension MainIsolateEventTypeExtension on MainIsolateEventType {
  MainIsolateEvent toEvent([dynamic argument]) =>
      MainIsolateEvent(this, argument);
}

enum WorkerIsolateEventType {
  onIsolateReady,

  /// args: ConnectedState
  onBlazeConnectStateChanged,

  /// args: DioException
  onApiRequestedError,

  /// args: [AttachmentRequest]
  requestDownloadAttachment,

  /// args: [String] pin message conversationId.
  showPinMessage,
}

extension WorkerIsolateEventTypeExtension on WorkerIsolateEventType {
  WorkerIsolateEvent toEvent([dynamic argument]) =>
      WorkerIsolateEvent(this, argument);
}

class IsolateEvent<T> {
  const IsolateEvent(this.type, [this.argument]);

  final T type;
  final dynamic argument;
}

// event from main isolate to worker isolate.
typedef MainIsolateEvent = IsolateEvent<MainIsolateEventType>;
// event from worker isolate to main isolate.
typedef WorkerIsolateEvent = IsolateEvent<WorkerIsolateEventType>;

abstract class AttachmentRequest {}

class TranscriptAttachmentDownloadRequest extends AttachmentRequest {
  TranscriptAttachmentDownloadRequest(this.message);

  final TranscriptMessage message;
}

class AttachmentDownloadRequest extends AttachmentRequest {
  AttachmentDownloadRequest(this.message);

  final Message message;
}

class AttachmentCancelRequest extends AttachmentRequest {
  AttachmentCancelRequest({required this.messageId});

  final String messageId;
}

class AttachmentDeleteRequest extends AttachmentRequest {
  AttachmentDeleteRequest({required this.message});

  final Message message;
}
