import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/dao/jobs_dao.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:uuid/uuid.dart';

class SendMessageHelper {
  SendMessageHelper(this._messagesDao, this._jobsDao);

  final MessagesDao _messagesDao;
  final JobsDao _jobsDao;

  void sendTextMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    final category =
        isPlain ? MessageCategory.plainText : MessageCategory.signalText;
    final message = Message(
      messageId: Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: content,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    await _messagesDao.insert(message, senderId);
    await _jobsDao.insertSendingJob(message.messageId, conversationId);
  }

  void sendImageMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainImage : MessageCategory.signalImage;
  }

  void sendVideoMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainVideo : MessageCategory.signalVideo;
  }

  void sendStickerMessage(String conversationId, String senderId,
      String content, bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainSticker : MessageCategory.signalSticker;
  }

  void sendDataMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainText : MessageCategory.signalText;
  }

  void sendContactMessage(String conversationId, String senderId,
      String content, bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainText : MessageCategory.signalText;
  }

  void sendAudioMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainText : MessageCategory.signalText;
  }

  void sendLiveMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainText : MessageCategory.signalText;
  }

  void sendPostMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainPost : MessageCategory.signalPost;
  }

  void sendLocationMessage(String conversationId, String senderId,
      String content, bool isPlain) async {
    // ignore: unused_local_variable
    final category = isPlain
        ? MessageCategory.plainLocation
        : MessageCategory.signalLocation;
  }

  void sendAppCardMessage(
      String conversationId, String senderId, String content, bool isPlain) {
    // ignore: unused_local_variable
    final category = MessageCategory.appCard;
  }

  void sendAppButtonGroup(
      String conversationId, String senderId, String content, bool isPlain) {
    // ignore: unused_local_variable
    final category = MessageCategory.appButtonGroup;
  }
}
