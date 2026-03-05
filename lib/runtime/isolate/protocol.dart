import 'package:dio/dio.dart';

import '../../blaze/blaze.dart';
import '../../db/mixin_database.dart';
import '../../workers/isolate_event.dart';
import '../sync/patch.dart';

sealed class WorkerCommand {
  const WorkerCommand();

  factory WorkerCommand.fromLegacy(MainIsolateEvent event) {
    switch (event.type) {
      case MainIsolateEventType.reconnectBlaze:
        return const ReconnectBlazeCommand();
      case MainIsolateEventType.disconnectBlazeWithTime:
        return const DisconnectBlazeWithTimeCommand();
      case MainIsolateEventType.updateSelectedConversation:
        return UpdateSelectedConversationCommand(
          conversationId: event.argument as String?,
        );
      case MainIsolateEventType.addAckJobs:
        return AddAckJobsCommand(jobs: event.argument as List<Job>);
      case MainIsolateEventType.addSessionAckJobs:
        return AddSessionAckJobsCommand(jobs: event.argument as List<Job>);
      case MainIsolateEventType.addSendingJob:
        return AddSendingJobCommand(job: event.argument as Job);
      case MainIsolateEventType.addUpdateAssetJob:
        return AddUpdateAssetJobCommand(job: event.argument as Job);
      case MainIsolateEventType.addUpdateStickerJob:
        return AddUpdateStickerJobCommand(job: event.argument as Job);
      case MainIsolateEventType.addUpdateTokenJob:
        return AddUpdateTokenJobCommand(job: event.argument as Job);
      case MainIsolateEventType.addSyncInscriptionMessageJob:
        return AddSyncInscriptionMessageJobCommand(job: event.argument as Job);
      case MainIsolateEventType.exit:
        return const ExitWorkerCommand();
    }
  }

  MainIsolateEvent toLegacy();
}

final class ReconnectBlazeCommand extends WorkerCommand {
  const ReconnectBlazeCommand();

  @override
  MainIsolateEvent toLegacy() => MainIsolateEventType.reconnectBlaze.toEvent();
}

final class DisconnectBlazeWithTimeCommand extends WorkerCommand {
  const DisconnectBlazeWithTimeCommand();

  @override
  MainIsolateEvent toLegacy() =>
      MainIsolateEventType.disconnectBlazeWithTime.toEvent();
}

final class UpdateSelectedConversationCommand extends WorkerCommand {
  const UpdateSelectedConversationCommand({required this.conversationId});

  final String? conversationId;

  @override
  MainIsolateEvent toLegacy() =>
      MainIsolateEventType.updateSelectedConversation.toEvent(conversationId);
}

final class AddAckJobsCommand extends WorkerCommand {
  const AddAckJobsCommand({required this.jobs});

  final List<Job> jobs;

  @override
  MainIsolateEvent toLegacy() => MainIsolateEventType.addAckJobs.toEvent(jobs);
}

final class AddSessionAckJobsCommand extends WorkerCommand {
  const AddSessionAckJobsCommand({required this.jobs});

  final List<Job> jobs;

  @override
  MainIsolateEvent toLegacy() =>
      MainIsolateEventType.addSessionAckJobs.toEvent(jobs);
}

final class AddSendingJobCommand extends WorkerCommand {
  const AddSendingJobCommand({required this.job});

  final Job job;

  @override
  MainIsolateEvent toLegacy() =>
      MainIsolateEventType.addSendingJob.toEvent(job);
}

final class AddUpdateAssetJobCommand extends WorkerCommand {
  const AddUpdateAssetJobCommand({required this.job});

  final Job job;

  @override
  MainIsolateEvent toLegacy() =>
      MainIsolateEventType.addUpdateAssetJob.toEvent(job);
}

final class AddUpdateStickerJobCommand extends WorkerCommand {
  const AddUpdateStickerJobCommand({required this.job});

  final Job job;

  @override
  MainIsolateEvent toLegacy() =>
      MainIsolateEventType.addUpdateStickerJob.toEvent(job);
}

final class AddUpdateTokenJobCommand extends WorkerCommand {
  const AddUpdateTokenJobCommand({required this.job});

  final Job job;

  @override
  MainIsolateEvent toLegacy() =>
      MainIsolateEventType.addUpdateTokenJob.toEvent(job);
}

final class AddSyncInscriptionMessageJobCommand extends WorkerCommand {
  const AddSyncInscriptionMessageJobCommand({required this.job});

  final Job job;

  @override
  MainIsolateEvent toLegacy() =>
      MainIsolateEventType.addSyncInscriptionMessageJob.toEvent(job);
}

final class ExitWorkerCommand extends WorkerCommand {
  const ExitWorkerCommand();

  @override
  MainIsolateEvent toLegacy() => MainIsolateEventType.exit.toEvent();
}

sealed class WorkerEvent {
  const WorkerEvent();

  factory WorkerEvent.fromLegacy(WorkerIsolateEvent event) {
    switch (event.type) {
      case WorkerIsolateEventType.onIsolateReady:
        return const WorkerIsolateReadyEvent();
      case WorkerIsolateEventType.onBlazeConnectStateChanged:
        return WorkerBlazeConnectStateChangedEvent(
          state: event.argument as ConnectedState,
        );
      case WorkerIsolateEventType.onApiRequestedError:
        return WorkerApiRequestedErrorEvent(
          error: event.argument as DioException,
        );
      case WorkerIsolateEventType.requestDownloadAttachment:
        return WorkerRequestDownloadAttachmentEvent(
          request: event.argument as AttachmentRequest,
        );
      case WorkerIsolateEventType.showPinMessage:
        return WorkerShowPinMessageEvent(
          conversationId: event.argument as String,
        );
      case WorkerIsolateEventType.syncPatches:
        return WorkerSyncPatchesEvent(
          patches: (event.argument as List).cast<SyncPatch>(),
        );
    }
  }

  WorkerIsolateEvent toLegacy();
}

final class WorkerIsolateReadyEvent extends WorkerEvent {
  const WorkerIsolateReadyEvent();

  @override
  WorkerIsolateEvent toLegacy() =>
      WorkerIsolateEventType.onIsolateReady.toEvent();
}

final class WorkerBlazeConnectStateChangedEvent extends WorkerEvent {
  const WorkerBlazeConnectStateChangedEvent({required this.state});

  final ConnectedState state;

  @override
  WorkerIsolateEvent toLegacy() =>
      WorkerIsolateEventType.onBlazeConnectStateChanged.toEvent(state);
}

final class WorkerApiRequestedErrorEvent extends WorkerEvent {
  const WorkerApiRequestedErrorEvent({required this.error});

  final DioException error;

  @override
  WorkerIsolateEvent toLegacy() =>
      WorkerIsolateEventType.onApiRequestedError.toEvent(error);
}

final class WorkerRequestDownloadAttachmentEvent extends WorkerEvent {
  const WorkerRequestDownloadAttachmentEvent({required this.request});

  final AttachmentRequest request;

  @override
  WorkerIsolateEvent toLegacy() =>
      WorkerIsolateEventType.requestDownloadAttachment.toEvent(request);
}

final class WorkerShowPinMessageEvent extends WorkerEvent {
  const WorkerShowPinMessageEvent({required this.conversationId});

  final String conversationId;

  @override
  WorkerIsolateEvent toLegacy() =>
      WorkerIsolateEventType.showPinMessage.toEvent(conversationId);
}

final class WorkerSyncPatchesEvent extends WorkerEvent {
  const WorkerSyncPatchesEvent({required this.patches});

  final List<SyncPatch> patches;

  @override
  WorkerIsolateEvent toLegacy() =>
      WorkerIsolateEventType.syncPatches.toEvent(patches);
}

final class RpcRequest {
  const RpcRequest({
    required this.requestId,
    required this.method,
    this.payload,
  });

  final String requestId;
  final String method;
  final Object? payload;
}

sealed class RpcResponse {
  const RpcResponse({required this.requestId});

  final String requestId;
}

final class RpcSuccessResponse extends RpcResponse {
  const RpcSuccessResponse({required super.requestId, this.result});

  final Object? result;
}

final class RpcErrorResponse extends RpcResponse {
  const RpcErrorResponse({
    required super.requestId,
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;
}

final class RpcCanceledResponse extends RpcResponse {
  const RpcCanceledResponse({required super.requestId});
}

final class RpcCancelRequest {
  const RpcCancelRequest({required this.requestId});

  final String requestId;
}

enum IsolateControlSignal {
  ping,
  pong,
  ready,
  stopping,
}

final class IsolateControlMessage {
  const IsolateControlMessage({
    required this.signal,
    required this.timestampMs,
  });

  final IsolateControlSignal signal;
  final int timestampMs;
}

sealed class IsolateWireMessage {
  const IsolateWireMessage();
}

final class IsolateCommandMessage extends IsolateWireMessage {
  const IsolateCommandMessage(this.command);

  final WorkerCommand command;
}

final class IsolateEventMessage extends IsolateWireMessage {
  const IsolateEventMessage(this.event);

  final WorkerEvent event;
}

final class IsolateRpcRequestMessage extends IsolateWireMessage {
  const IsolateRpcRequestMessage(this.request);

  final RpcRequest request;
}

final class IsolateRpcResponseMessage extends IsolateWireMessage {
  const IsolateRpcResponseMessage(this.response);

  final RpcResponse response;
}

final class IsolateRpcCancelMessage extends IsolateWireMessage {
  const IsolateRpcCancelMessage(this.cancelRequest);

  final RpcCancelRequest cancelRequest;
}

final class IsolateControlWireMessage extends IsolateWireMessage {
  const IsolateControlWireMessage(this.control);

  final IsolateControlMessage control;
}
