import 'package:dio/dio.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../db/mixin_database.dart';
import '../utils/mixin_api_client.dart';

enum MainIsolateEventType {
  reconnectBlaze,
  disconnectBlazeWithTime,
  requireUpgrade,
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

  /// args: [WorkerApiError]
  onApiRequestedError,

  onUpgradeRequired,

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

class WorkerApiError {
  const WorkerApiError({
    required this.code,
    this.authorizationHeader,
    this.serverTime,
    this.requestTime,
  });

  final int code;
  final String? authorizationHeader;
  final int? serverTime;
  final DateTime? requestTime;

  static WorkerApiError? fromDioException(DioException e) {
    if (e is! MixinApiError) return null;
    final error = e.error;
    if (error is! MixinError) return null;
    final authorizationValue = e.requestOptions.headers['Authorization'];
    final authorizationHeader = authorizationValue is String
        ? authorizationValue
        : authorizationValue is Iterable
        ? authorizationValue.whereType<String>().firstOrNull
        : null;
    final serverTime = int.tryParse(
      e.response?.headers.value('x-server-time') ?? '',
    );
    final requestTime = e.requestOptions.extra[kRequestTimeStampKey];
    return WorkerApiError(
      code: error.code,
      authorizationHeader: authorizationHeader,
      serverTime: serverTime,
      requestTime: requestTime is DateTime ? requestTime : null,
    );
  }
}

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
