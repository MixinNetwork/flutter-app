import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../constants/constants.dart';
import '../db/extension/job.dart';
import '../utils/extension/extension.dart';
import 'injector.dart';
import 'job/ack_job.dart';

class DecryptCall extends Injector {
  DecryptCall(
    super.accountId,
    super.database,
    super.client,
    this._ackJob,
  );

  final AckJob _ackJob;

  Future<void> process(BlazeMessageData data) async {
    d('DecryptCall process: ${data.toJson()}');
    try {
      await syncConversion(data.conversationId);
      if (await isExistMessage(data.messageId)) {
        await _updateRemoteMessageStatus(
            data.messageId, MessageStatus.delivered);
        return;
      }
      if (data.category.isWebRtc) {
        await _processWebRtc(data);
      } else if (data.category.isKraken) {
        d('DecryptCall kraken, not supported yet');
        await _updateRemoteMessageStatus(
            data.messageId, MessageStatus.delivered);
      } else {
        await _updateRemoteMessageStatus(
            data.messageId, MessageStatus.delivered);
      }
    } catch (error, stakeTrace) {
      e('DecryptCall failed', error, stakeTrace);
      await _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
    }
  }

  Future<void> _processWebRtc(BlazeMessageData data) async {
    d('DecryptCall processWebRtc: ${data.toJson()}');
  }

  Future<void> _updateRemoteMessageStatus(
      String messageId, MessageStatus status) async {
    if (status != MessageStatus.delivered && status != MessageStatus.read) {
      return;
    }
    await _ackJob
        .add([createAckJob(kAcknowledgeMessageReceipts, messageId, status)]);
  }
}
