import 'dart:convert';

import 'package:flutter_app/db/dao/message_dao.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/widgets/message/send_message_dialog/attachment_extra.dart';
import 'package:flutter_app/workers/job/sending_job.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  test('resent attachment payload can be decoded by the receiver', () async {
    final extra = jsonEncode(
      AttachmentExtra(
        attachmentId: 'attachment',
        messageId: 'message',
        createdAt: '2026-10-31T12:00:00Z',
      ),
    );
    final message = SendingMessage(
      messageId: 'message',
      conversationId: 'conversation',
      userId: 'sender',
      category: MessageCategory.signalImage,
      content: extra,
      mediaMimeType: 'image/png',
      mediaSize: 1024,
      mediaWidth: 20,
      mediaHeight: 10,
      mediaKey: 'a2V5',
      mediaDigest: 'ZGlnZXN0',
      thumbImage: 'thumb',
      caption: 'caption',
      status: MessageStatus.read,
      createdAt: DateTime.utc(2026),
    );

    // The stored content is not a payload: the receiver rejects it.
    expect(() => base64Decode(extra), throwsFormatException);

    final payload = AttachmentMessage.fromJson(
      jsonDecode(
            utf8.decode(base64Decode(await attachmentResendPayload(message))),
          )
          as Map<String, dynamic>,
    );
    expect(payload.attachmentId, 'attachment');
    expect(payload.key, 'a2V5');
    expect(payload.digest, 'ZGlnZXN0');
    expect(payload.mimeType, 'image/png');
    expect(payload.size, 1024);
    expect(payload.width, 20);
    expect(payload.height, 10);
    expect(payload.thumbnail, 'thumb');
    expect(payload.caption, 'caption');
    expect(payload.createdAt, '2026-10-31T12:00:00Z');
  });

  test('resent attachment keeps content that is already a payload', () async {
    final payload = base64Encode(utf8.encode('{"attachment_id":"attachment"}'));
    final message = SendingMessage(
      messageId: 'message',
      conversationId: 'conversation',
      userId: 'sender',
      category: MessageCategory.signalImage,
      content: payload,
      status: MessageStatus.read,
      createdAt: DateTime.utc(2026),
    );

    expect(await attachmentResendPayload(message), payload);
  });
}
