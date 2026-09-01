@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/utils/attachment/attachment_util.dart';
import 'package:flutter_app/utils/attachment/download_key_value.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/utils/property/setting_property.dart';
import 'package:flutter_app/workers/decrypt_message.dart';
import 'package:flutter_app/workers/job/sending_job.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class _DeletingTranscriptAttachmentUtil extends AttachmentUtil {
  _DeletingTranscriptAttachmentUtil(
    Client client,
    MixinDatabase database,
    SettingPropertyStorage settingProperties,
    String mediaPath, {
    required this.isNotPendingReturned,
  }) : _database = database,
       super(
         client,
         database.messageDao,
         database.transcriptMessageDao,
         settingProperties,
         mediaPath,
       );

  final MixinDatabase _database;
  final Completer<void> isNotPendingReturned;

  @override
  Future<bool> isNotPending(
    String messageId, {
    String? transcriptId,
  }) async {
    final result = await super.isNotPending(
      messageId,
      transcriptId: transcriptId,
    );
    final parentId = transcriptId!;
    await removeAttachmentJobsByParentId(parentId);
    await (_database.delete(_database.transcriptMessages)..where(
          (row) =>
              row.transcriptId.equals(parentId) &
              row.messageId.equals(messageId),
        ))
        .go();
    isNotPendingReturned.complete();
    return result;
  }
}

class _RecordingTranscriptAttachmentUtil extends AttachmentUtil {
  _RecordingTranscriptAttachmentUtil(
    Client client,
    MixinDatabase database,
    SettingPropertyStorage settingProperties,
    String mediaPath,
  ) : super(
        client,
        database.messageDao,
        database.transcriptMessageDao,
        settingProperties,
        mediaPath,
      );

  final paths = <String>[];

  @override
  File getAttachmentFile(
    String category,
    String? conversationId,
    String messageId,
    String? mediaName, {
    String? mimeType,
    bool isTranscript = false,
    String? transcriptId,
  }) {
    final file = super.getAttachmentFile(
      category,
      conversationId,
      messageId,
      mediaName,
      mimeType: mimeType,
      isTranscript: isTranscript,
      transcriptId: transcriptId,
    );
    paths.add(file.path);
    return file;
  }

  @override
  Future<bool> isNotPending(
    String messageId, {
    String? transcriptId,
  }) async => true;
}

class _AttachmentTestContext {
  _AttachmentTestContext(this.database, this.mediaDirectory);

  static Future<_AttachmentTestContext> create(String key) async {
    final database = MixinDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'attachment-util-documents',
    );
    mixinDocumentsDirectory = documentsDirectory;
    addTearDown(() => documentsDirectory.delete(recursive: true));
    await DownloadKeyValue.instance.init(key);
    addTearDown(DownloadKeyValue.instance.delete);
    final mediaDirectory = await Directory.systemTemp.createTemp(
      'attachment-util-test',
    );
    addTearDown(() => mediaDirectory.delete(recursive: true));
    return _AttachmentTestContext(database, mediaDirectory);
  }

  final MixinDatabase database;
  final Directory mediaDirectory;
}

void main() {
  setUpAll(EventBus.initialize);
  test('clears stale media paths for incoming transcript attachments', () {
    final message = TranscriptMessage(
      transcriptId: 'transcript-id',
      messageId: 'child-id',
      category: MessageCategory.plainImage,
      createdAt: DateTime(2026),
      content: 'attachment-id',
      mediaUrl: 'stale.png',
      mediaStatus: MediaStatus.done,
    );

    final normalized = normalizeIncomingTranscriptMessage(message);

    expect(normalized.mediaUrl, isNull);
    expect(normalized.mediaStatus, MediaStatus.canceled);
  });
  test('omits local media paths from outgoing transcript JSON', () {
    final json = transcriptMessageToSendingJson(
      TranscriptMessage(
        transcriptId: 'transcript-id',
        messageId: 'child-id',
        category: MessageCategory.plainImage,
        createdAt: DateTime(2026),
        content: 'attachment-id',
        mediaUrl: 'local.png',
        mediaDuration: '42',
        mediaStatus: MediaStatus.canceled,
      ),
    );

    expect(json['content'], 'attachment-id');
    expect(json['media_duration'], 42);
    expect(json.containsKey('media_url'), isFalse);
    expect(json.containsKey('media_status'), isFalse);
  });

  test('downloads the requested transcript child once by both IDs', () async {
    final context = await _AttachmentTestContext.create(
      'attachment-util-exact',
    );
    final database = context.database;
    final mediaDirectory = context.mediaDirectory;

    await database.transcriptMessageDao.insertAll([
      TranscriptMessage(
        transcriptId: 'target-transcript',
        messageId: 'child-id',
        category: MessageCategory.plainImage,
        createdAt: DateTime(2026),
        content: 'target-attachment',
        mediaUrl: 'stale.png',
        mediaMimeType: 'image/png',
        mediaWidth: 1,
        mediaHeight: 1,
        mediaStatus: MediaStatus.canceled,
      ),
      TranscriptMessage(
        transcriptId: 'other-transcript',
        messageId: 'child-id',
        category: MessageCategory.plainImage,
        createdAt: DateTime(2026),
        content: 'other-attachment',
        mediaMimeType: 'image/png',
        mediaSize: 3,
        mediaWidth: 1,
        mediaHeight: 1,
        mediaStatus: MediaStatus.canceled,
      ),
    ]);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requestedPaths = <String>[];
    final baseUrl = 'http://${server.address.host}:${server.port}';
    final subscription = server.listen((request) async {
      requestedPaths.add(request.uri.path);
      final response = request.response;
      if (request.uri.path == '/attachments/target-attachment') {
        response.headers.contentType = ContentType.json;
        response.write(
          jsonEncode({
            'data': {
              'attachment_id': 'target-attachment',
              'created_at': '2026-01-01T00:00:00Z',
              'view_url': null,
            },
          }),
        );
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    });
    addTearDown(() async {
      await subscription.cancel();
      await server.close(force: true);
    });

    final util = AttachmentUtil(
      Client(baseUrl: baseUrl, accessToken: 'test', httpLogLevel: null),
      database.messageDao,
      database.transcriptMessageDao,
      SettingPropertyStorage(database.propertyDao),
      mediaDirectory.path,
    );

    await Future.wait([
      util.downloadAttachment(
        messageId: 'child-id',
        transcriptId: 'target-transcript',
      ),
      util.downloadAttachment(
        messageId: 'child-id',
        transcriptId: 'target-transcript',
      ),
    ]);

    final target = await database.transcriptMessageDao
        .transcriptMessageByIds('target-transcript', 'child-id')
        .getSingle();
    final other = await database.transcriptMessageDao
        .transcriptMessageByIds('other-transcript', 'child-id')
        .getSingle();

    expect(target.mediaStatus, MediaStatus.pending);
    expect(other.mediaStatus, MediaStatus.canceled);
    expect(requestedPaths, ['/attachments/target-attachment']);
  });
  test(
    'isolates concurrent transcript downloads with the same child ID',
    () async {
      final context = await _AttachmentTestContext.create(
        'attachment-util-transcript-isolation',
      );
      final database = context.database;
      final mediaDirectory = context.mediaDirectory;

      const firstTranscriptId = 'first-transcript';
      const secondTranscriptId = 'second-transcript';
      const childMessageId = 'shared-child-id';
      const firstAttachmentId = 'first-attachment';
      const secondAttachmentId = 'second-attachment';

      await database.transcriptMessageDao.insertAll([
        TranscriptMessage(
          transcriptId: firstTranscriptId,
          messageId: childMessageId,
          category: MessageCategory.plainImage,
          createdAt: DateTime(2026),
          content: firstAttachmentId,
          mediaMimeType: 'image/png',
          mediaWidth: 1,
          mediaHeight: 1,
          mediaStatus: MediaStatus.canceled,
        ),
        TranscriptMessage(
          transcriptId: secondTranscriptId,
          messageId: childMessageId,
          category: MessageCategory.plainImage,
          createdAt: DateTime(2026),
          content: secondAttachmentId,
          mediaMimeType: 'image/png',
          mediaWidth: 1,
          mediaHeight: 1,
          mediaStatus: MediaStatus.canceled,
        ),
      ]);

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requestedAttachmentIds = <String>[];
      final metadataRequestsReceived = Completer<void>();
      final baseUrl = 'http://${server.address.host}:${server.port}';
      final subscription = server.listen((request) async {
        final attachmentId = request.uri.path.substring(
          '/attachments/'.length,
        );
        requestedAttachmentIds.add(attachmentId);
        if (requestedAttachmentIds.length == 2) {
          metadataRequestsReceived.complete();
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'data': {
              'attachment_id': attachmentId,
              'created_at': '2026-01-01T00:00:00Z',
              'view_url': null,
            },
          }),
        );
        await request.response.close();
      });
      addTearDown(() async {
        await subscription.cancel();
        await server.close(force: true);
      });

      final util = _RecordingTranscriptAttachmentUtil(
        Client(baseUrl: baseUrl, accessToken: 'test', httpLogLevel: null),
        database,
        SettingPropertyStorage(database.propertyDao),
        mediaDirectory.path,
      );

      final downloads = Future.wait([
        util.downloadAttachment(
          messageId: childMessageId,
          transcriptId: firstTranscriptId,
        ),
        util.downloadAttachment(
          messageId: childMessageId,
          transcriptId: secondTranscriptId,
        ),
      ]);
      await metadataRequestsReceived.future;
      await downloads;

      expect(
        requestedAttachmentIds.toSet(),
        {firstAttachmentId, secondAttachmentId},
      );
      expect(util.paths.toSet(), hasLength(2));
      expect(
        util.paths.singleWhere((path) => path.contains(firstTranscriptId)),
        contains(childMessageId),
      );
      expect(
        util.paths.singleWhere((path) => path.contains(secondTranscriptId)),
        contains(childMessageId),
      );
      expect(
        util.convertAbsolutePath(
          category: MessageCategory.plainImage,
          fileName: null,
          messageId: childMessageId,
          isTranscript: true,
        ),
        '',
      );
    },
  );

  test(
    'aborts an in-flight transcript download when its row is deleted',
    () async {
      final context = await _AttachmentTestContext.create(
        'attachment-util-deleted-row',
      );
      final database = context.database;
      final mediaDirectory = context.mediaDirectory;

      const transcriptId = 'deleted-parent';
      const messageId = 'deleted-child';
      const attachmentId = 'deleted-attachment';
      const key = '$transcriptId|$messageId';

      await database.transcriptMessageDao.insertAll([
        TranscriptMessage(
          transcriptId: transcriptId,
          messageId: messageId,
          category: MessageCategory.plainImage,
          createdAt: DateTime(2026),
          content: attachmentId,
          mediaMimeType: 'image/png',
          mediaStatus: MediaStatus.pending,
        ),
      ]);

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requestReceived = Completer<void>();
      final releaseResponse = Completer<void>();
      final baseUrl = 'http://${server.address.host}:${server.port}';
      final subscription = server.listen((request) async {
        final response = request.response;
        if (request.uri.path == '/attachments/$attachmentId') {
          requestReceived.complete();
          await releaseResponse.future;
          response.headers.contentType = ContentType.json;
          response.write(
            jsonEncode({
              'data': {
                'attachment_id': attachmentId,
                'created_at': '2026-01-01T00:00:00Z',
                'view_url': '$baseUrl/unused',
              },
            }),
          );
        } else {
          response.statusCode = HttpStatus.notFound;
        }
        await response.close();
      });
      addTearDown(() async {
        if (!releaseResponse.isCompleted) releaseResponse.complete();
        await subscription.cancel();
        await server.close(force: true);
      });

      final util = AttachmentUtil(
        Client(baseUrl: baseUrl, accessToken: 'test', httpLogLevel: null),
        database.messageDao,
        database.transcriptMessageDao,
        SettingPropertyStorage(database.propertyDao),
        mediaDirectory.path,
      );

      final download = util.downloadAttachment(
        messageId: messageId,
        transcriptId: transcriptId,
      );
      await requestReceived.future;
      await (database.delete(database.transcriptMessages)..where(
            (row) =>
                row.transcriptId.equals(transcriptId) &
                row.messageId.equals(messageId),
          ))
          .go();

      try {
        expect(
          await util.isNotPending(messageId, transcriptId: transcriptId),
          isTrue,
        );
      } finally {
        releaseResponse.complete();
        await download;
      }

      expect(DownloadKeyValue.instance.messageIds, isNot(contains(key)));
    },
  );

  test(
    'does not recreate a deleted transcript attachment job after pending check',
    () async {
      final context = await _AttachmentTestContext.create(
        'attachment-util-deleted-after-pending',
      );
      final database = context.database;
      final mediaDirectory = context.mediaDirectory;

      const transcriptId = 'deleted-after-pending-parent';
      const messageId = 'deleted-after-pending-child';
      const attachmentId = 'deleted-after-pending-attachment';
      const key = '$transcriptId|$messageId';

      await database.transcriptMessageDao.insertAll([
        TranscriptMessage(
          transcriptId: transcriptId,
          messageId: messageId,
          category: MessageCategory.plainImage,
          createdAt: DateTime(2026),
          content: attachmentId,
          mediaMimeType: 'image/png',
          mediaStatus: MediaStatus.canceled,
        ),
      ]);

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final releaseFileResponse = Completer<void>();
      final baseUrl = 'http://${server.address.host}:${server.port}';
      final subscription = server.listen((request) async {
        final response = request.response;
        if (request.uri.path == '/attachments/$attachmentId') {
          response.headers.contentType = ContentType.json;
          response.write(
            jsonEncode({
              'data': {
                'attachment_id': attachmentId,
                'created_at': '2026-01-01T00:00:00Z',
                'view_url': '$baseUrl/files/$attachmentId',
              },
            }),
          );
        } else if (request.uri.path == '/files/$attachmentId') {
          await releaseFileResponse.future;
          response.add([1, 2, 3]);
        } else {
          response.statusCode = HttpStatus.notFound;
        }
        await response.close();
      });
      addTearDown(() async {
        if (!releaseFileResponse.isCompleted) releaseFileResponse.complete();
        await subscription.cancel();
        await server.close(force: true);
      });

      final util = _DeletingTranscriptAttachmentUtil(
        Client(baseUrl: baseUrl, accessToken: 'test', httpLogLevel: null),
        database,
        SettingPropertyStorage(database.propertyDao),
        mediaDirectory.path,
        isNotPendingReturned: Completer<void>(),
      );

      final download = util.downloadAttachment(
        messageId: messageId,
        transcriptId: transcriptId,
      );
      try {
        await util.isNotPendingReturned.future;
        await Future<void>.delayed(Duration.zero);

        expect(DownloadKeyValue.instance.messageIds, isNot(contains(key)));
        expect(
          util.downloadingParentIds,
          isNot(contains(transcriptId)),
        );
      } finally {
        if (!releaseFileResponse.isCompleted) {
          releaseFileResponse.complete();
        }
        await download;
      }
    },
  );

  test(
    'removes persisted attachment jobs by parent without sibling leakage',
    () async {
      final context = await _AttachmentTestContext.create(
        'attachment-util-parent-cleanup',
      );
      final database = context.database;
      final mediaDirectory = context.mediaDirectory;

      final util = AttachmentUtil(
        Client(
          baseUrl: 'http://127.0.0.1',
          accessToken: 'test',
          httpLogLevel: null,
        ),
        database.messageDao,
        database.transcriptMessageDao,
        SettingPropertyStorage(database.propertyDao),
        mediaDirectory.path,
      );

      for (final key in const [
        'target-parent|target-child',
        'target-parent|other-child',
        'sibling-parent|sibling-child',
      ]) {
        await DownloadKeyValue.instance.addMessageId(key);
      }

      expect(
        util.downloadingParentIds.toSet(),
        {'target-parent', 'sibling-parent'},
      );

      await util.removeAttachmentJobsByParentId('target-parent');

      expect(
        DownloadKeyValue.instance.messageIds.toSet(),
        {'sibling-parent|sibling-child'},
      );
      expect(util.downloadingParentIds.toSet(), {'sibling-parent'});

      expect(
        await util.cancelProgressAttachmentJob(
          'sibling-child',
          transcriptId: 'sibling-parent',
        ),
        isFalse,
      );
      expect(DownloadKeyValue.instance.messageIds, isEmpty);
    },
  );
}
