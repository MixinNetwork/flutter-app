import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../../blaze/vo/recall_message.dart';
import '../../constants/constants.dart';
import '../../utils/extension/extension.dart';
import '../../utils/load_balancer_utils.dart';
import '../../utils/logger.dart';
import '../mixin_database.dart';

Job createAckJob(
  String action,
  String messageId,
  MessageStatus status, {
  int? expireAt,
}) {
  final blazeMessage = BlazeAckMessage(
    messageId: messageId,
    status: enumConvertToString(status)!.toUpperCase(),
    expireAt: expireAt,
  );
  final jobId =
      '${blazeMessage.messageId}${blazeMessage.status}$action'.nameUuid();
  d('createAckJob messageId: ${blazeMessage.messageId} action: $action jobId: $jobId, status: $status expireAt: $expireAt');
  return Job(
      jobId: jobId,
      action: action,
      priority: 5,
      blazeMessage: jsonEncode(blazeMessage),
      createdAt: DateTime.now(),
      runCount: 0);
}

Future<Job> createMentionReadAckJob(
        String conversationId, String messageId) async =>
    Job(
      jobId: const Uuid().v4(),
      action: kCreateMessage,
      createdAt: DateTime.now(),
      conversationId: conversationId,
      runCount: 0,
      priority: 5,
      blazeMessage: await jsonEncodeWithIsolate(BlazeAckMessage(
        messageId: messageId,
        status: 'MENTION_READ',
        expireAt: null,
      )),
    );

Job createSendPinJob(String conversationId, String encoded) => Job(
      conversationId: conversationId,
      jobId: const Uuid().v4(),
      action: kPinMessage,
      priority: 5,
      blazeMessage: encoded,
      createdAt: DateTime.now(),
      runCount: 0,
    );

Future<Job> createSendRecallJob(
        String conversationId, String messageId) async =>
    Job(
      conversationId: conversationId,
      jobId: const Uuid().v4(),
      action: kRecallMessage,
      priority: 5,
      blazeMessage: await jsonEncodeWithIsolate(RecallMessage(messageId)),
      createdAt: DateTime.now(),
      runCount: 0,
    );

Job createUpdateStickerJob(String stickerId) => Job(
      jobId: const Uuid().v4(),
      action: kUpdateSticker,
      priority: 5,
      runCount: 0,
      createdAt: DateTime.now(),
      blazeMessage: stickerId,
    );

Job createUpdateAssetJob(String assetId) => Job(
      jobId: const Uuid().v4(),
      action: kUpdateAsset,
      priority: 5,
      runCount: 0,
      createdAt: DateTime.now(),
      blazeMessage: assetId,
    );

Job createUpdateTokenJob(String assetId) => Job(
      jobId: const Uuid().v4(),
      action: kUpdateToken,
      priority: 5,
      runCount: 0,
      createdAt: DateTime.now(),
      blazeMessage: assetId,
    );

Job createMigrationFtsJob(int? messageRowId) => Job(
      jobId: const Uuid().v4(),
      action: kMigrateFts,
      priority: 5,
      runCount: 0,
      createdAt: DateTime.now(),
      blazeMessage: messageRowId?.toString(),
    );

Job createCleanupQuoteContentJob() => Job(
      jobId: const Uuid().v4(),
      action: kCleanupQuoteContent,
      priority: 5,
      runCount: 0,
      createdAt: DateTime.now(),
    );
