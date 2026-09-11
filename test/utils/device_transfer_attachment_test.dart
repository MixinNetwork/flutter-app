@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/attachment/attachment_util.dart';
import 'package:flutter_app/utils/device_transfer/cipher.dart';
import 'package:flutter_app/utils/device_transfer/device_transfer_receiver.dart';
import 'package:flutter_app/utils/device_transfer/socket_wrapper.dart';
import 'package:flutter_app/utils/device_transfer/transfer_data_command.dart';
import 'package:flutter_app/utils/device_transfer/transfer_data_message.dart';
import 'package:flutter_app/utils/device_transfer/transfer_data_transcript_message.dart';
import 'package:flutter_app/utils/device_transfer/transfer_protocol.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

void main() {
  late Directory directory;
  late AttachmentUtilBase attachments;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('transfer-security-');
    mixinDocumentsDirectory = directory;
    final media = Directory(p.join(directory.path, 'Media'))..createSync();
    Directory(p.join(media.path, 'Transcripts')).createSync();
    attachments = AttachmentUtilBase(media.path);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  test('migration confines normal and transcript paths to Media', () {
    for (final transcript in [false, true]) {
      String resolve(String name, {String conversation = 'conversation'}) =>
          attachments.convertTransferAttachmentPath(
            fileName: name,
            category: 'SIGNAL_IMAGE',
            conversationId: conversation,
            isTranscript: transcript,
          );

      expect(resolve('photo.jpg'), startsWith('${attachments.mediaPath}/'));
      expect(
        resolve('nested/photo.jpg'),
        startsWith('${attachments.mediaPath}/'),
      );
      expect(resolve(''), isEmpty);
      expect(resolve('../../../../outside.jpg'), isEmpty);
      expect(resolve(p.join(directory.path, 'outside.jpg')), isEmpty);
      expect(resolve('${attachments.mediaPath}-other/photo.jpg'), isEmpty);
      if (!transcript) {
        expect(
          resolve('photo.jpg', conversation: '../../../../outside'),
          isEmpty,
        );
      }
      final parent = transcript
          ? attachments.transcriptPath
          : attachments.getImagesPath('conversation');
      Directory(parent).createSync(recursive: true);
      Link(p.join(parent, 'escape')).createSync(directory.path);
      expect(resolve('escape/outside.jpg'), isEmpty);
      Link(p.join(parent, 'photo-link.jpg')).createSync(
        p.join(directory.path, 'not-created.jpg'),
      );
      expect(resolve('photo-link.jpg'), isEmpty);
      expect(File(p.join(directory.path, 'outside.jpg')).existsSync(), isFalse);
    }
  });

  test(
    'receiver writes valid attachments and rejects remote escape paths',
    () async {
      EventBus.initialize();
      final database = Database(
        MixinDatabase(NativeDatabase.memory()),
        FtsDatabase(NativeDatabase.memory()),
      );
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final connected = server.first;
      final finished = Completer<void>();
      final receiver = DeviceTransferReceiver(
        database: database,
        attachmentUtil: attachments,
        userId: 'self',
        deviceId: 'desktop',
        protocolTempFileDir: p.join(directory.path, 'temp'),
        onReceiverSucceed: finished.complete,
        onReceiverFailed: () =>
            finished.completeError(StateError('transfer failed')),
      );
      final key = generateTransferKey();
      await receiver.connectToServer('127.0.0.1', server.port, 1234, key);
      final peer = await connected;
      final subscription = peer.listen((_) {});
      final socket = TransferSocket(peer, key);
      final source = File(p.join(directory.path, 'source'))
        ..writeAsStringSync('attachment');
      try {
        for (final transcript in [false, true]) {
          for (final name in [
            'valid.jpg',
            if (transcript) '../../escape.jpg' else '../../../escape.jpg',
            p.join(directory.path, 'absolute.jpg'),
          ]) {
            final id = const Uuid().v4();
            if (transcript) {
              await socket.addTranscriptMessage(
                TransferDataTranscriptMessage.fromDbTranscriptMessage(
                  TranscriptMessage(
                    transcriptId: 'transcript',
                    messageId: id,
                    category: 'SIGNAL_IMAGE',
                    createdAt: DateTime(2026),
                    mediaUrl: name,
                  ),
                ),
              );
            } else {
              await socket.addMessage(
                TransferDataMessage.fromDbMessage(
                  Message(
                    messageId: id,
                    conversationId: 'conversation',
                    userId: 'self',
                    category: 'SIGNAL_IMAGE',
                    createdAt: DateTime(2026),
                    status: sdk.MessageStatus.delivered,
                    mediaUrl: name,
                  ),
                ),
              );
            }
            await TransferAttachmentPacket(
              messageId: id,
              path: source.path,
            ).write(socket, key);
          }
        }
        await socket.addCommand(
          TransferDataCommand.simple(
            deviceId: 'mobile',
            action: kTransferCommandActionFinish,
          ),
        );
        await socket.addCommand(
          TransferDataCommand.simple(
            deviceId: 'mobile',
            action: kTransferCommandActionClose,
          ),
        );
        await finished.future.timeout(const Duration(seconds: 10));
        expect(
          File(
            p.join(attachments.getImagesPath('conversation'), 'valid.jpg'),
          ).readAsStringSync(),
          'attachment',
        );
        expect(
          File(
            p.join(attachments.transcriptPath, 'valid.jpg'),
          ).readAsStringSync(),
          'attachment',
        );
        expect(
          File(p.join(directory.path, 'absolute.jpg')).existsSync(),
          isFalse,
        );
        expect(
          Directory(directory.path)
              .listSync(recursive: true)
              .whereType<File>()
              .any((file) => p.basename(file.path) == 'escape.jpg'),
          isFalse,
        );
      } finally {
        receiver.close();
        socket.destroy();
        await subscription.cancel();
        await server.close();
        await database.dispose();
      }
    },
  );
}
