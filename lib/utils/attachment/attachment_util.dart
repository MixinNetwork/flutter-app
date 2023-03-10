import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../db/dao/message_dao.dart';
import '../../db/dao/transcript_message_dao.dart';
import '../../db/mixin_database.dart';
import '../../db/util/util.dart';
import '../../enum/media_status.dart';
import '../../widgets/message/send_message_dialog/attachment_extra.dart';
import '../../widgets/toast.dart';
import '../crypto_util.dart';
import '../extension/extension.dart';
import '../file.dart';
import '../load_balancer_utils.dart';
import '../logger.dart';
import 'download_key_value.dart';

part 'attachment_download_job.dart';

part 'attachment_upload_job.dart';

final _dio = Dio(BaseOptions(
  connectTimeout: const Duration(milliseconds: 150 * 1000),
  receiveTimeout: const Duration(milliseconds: 150 * 1000),
));

// isolate kill message
const _killMessage = 'kill';

abstract class _AttachmentJobBase {
  int total = 0;
  int current = 0;

  void cancel();

  void updateProgress(int current, int total) {
    this.current = current;
    this.total = total;
  }

  double get progress {
    if (total == 0) return 0;
    return min(current / total, 1);
  }
}

class AttachmentUtil extends ChangeNotifier {
  AttachmentUtil(
    this._client,
    this._messageDao,
    this._transcriptMessageDao,
    this.mediaPath,
  ) {
    final httpClientAdapter = _dio.httpClientAdapter;
    if (httpClientAdapter is IOHttpClientAdapter) {
      httpClientAdapter.onHttpClientCreate = (client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      };
    } else {
      w('httpClientAdapter is not IOHttpClientAdapter');
    }
    transcriptPath = p.join(mediaPath, 'Transcripts');
    Directory(transcriptPath).create(recursive: true);
  }

  final String mediaPath;
  late final String transcriptPath;
  final MessageDao _messageDao;
  final TranscriptMessageDao _transcriptMessageDao;
  final Client _client;

  final _attachmentJob = <String, _AttachmentJobBase>{};

  /// check if the attachment is downloaded, if not, return false, otherwise sync it and  return true
  Future<bool> checkSyncMessageMedia(String messageId) async {
    Future<bool> checkDownloaded() async =>
        await _messageDao.messageHasMediaStatus(messageId, MediaStatus.done) ||
        await _messageDao.transcriptMessageHasMediaStatus(
            messageId, MediaStatus.done);

    if (!_hasAttachmentJob(messageId) && await checkDownloaded()) {
      await syncMessageMedia(messageId);
      await _updateTranscriptMessageStatus(messageId);
      return true;
    }
    return false;
  }

  Future<void> downloadAttachment({
    required String messageId,
  }) async {
    if (await checkSyncMessageMedia(messageId)) return;

    await _messageDao.updateMediaStatus(messageId, MediaStatus.pending);

    AttachmentMessage? attachmentMessage;

    final list = await Future.wait([
      _messageDao.findMessageByMessageId(messageId),
      _transcriptMessageDao
          .transcriptMessageByMessageId(messageId)
          .getSingleOrNull(),
    ]);
    final message = list.first as Message?;
    final transcriptMessage = list[1] as TranscriptMessage?;

    if (message != null) {
      attachmentMessage = AttachmentMessage(
        message.mediaKey,
        message.mediaDigest,
        message.content!,
        message.mediaMimeType!,
        message.mediaSize!,
        message.name,
        message.mediaWidth,
        message.mediaHeight,
        message.thumbImage,
        int.tryParse(message.mediaDuration ?? '0'),
        message.mediaWaveform,
        null,
        null,
      );
    }

    if (transcriptMessage != null && attachmentMessage == null) {
      attachmentMessage = AttachmentMessage(
        transcriptMessage.mediaKey,
        transcriptMessage.mediaDigest,
        transcriptMessage.content!,
        transcriptMessage.mediaMimeType!,
        transcriptMessage.mediaSize!,
        transcriptMessage.userFullName,
        transcriptMessage.mediaWidth,
        transcriptMessage.mediaHeight,
        transcriptMessage.thumbImage,
        int.tryParse(transcriptMessage.mediaDuration ?? '0'),
        transcriptMessage.mediaWaveform,
        null,
        null,
      );
    }

    final content = message?.content ?? transcriptMessage?.content;
    final category = message?.category ?? transcriptMessage?.category;
    final conversationId = message?.conversationId;

    if (category == null || content == null) {
      await cancelProgressAttachmentJob(messageId);
      return;
    }

    String attachmentId;
    bool? shareable;

    try {
      final json = await jsonDecodeWithIsolate(content);
      final attachmentExtra =
          AttachmentExtra.fromJson(json as Map<String, dynamic>);
      attachmentId = attachmentExtra.attachmentId;
      shareable = attachmentExtra.shareable;
    } catch (e) {
      attachmentId = content;
    }

    final file = getAttachmentFile(
      category,
      conversationId,
      messageId,
      message?.name ?? transcriptMessage?.mediaName,
      mimeType: attachmentMessage?.mimeType ??
          message?.mediaMimeType ??
          transcriptMessage?.mediaMimeType,
      isTranscript: message == null,
    );
    final path = file.absolute.path;
    if (file.existsSync()) await file.delete();

    try {
      final response = await _client.attachmentApi.getAttachment(attachmentId);
      d('download ${response.data.viewUrl}');

      if (await isNotPending(messageId)) return;

      if (response.data.viewUrl != null) {
        String? mediaKey;
        String? mediaDigest;

        void setKeyAndDigestInvalid(String? _mediaKey, String? _mediaDigest) {
          mediaKey = _mediaKey?.trim().isEmpty ?? true ? null : _mediaKey;
          mediaDigest =
              _mediaDigest?.trim().isEmpty ?? true ? null : _mediaDigest;
        }

        setKeyAndDigestInvalid(
          attachmentMessage?.key as String?,
          attachmentMessage?.digest as String?,
        );

        if ((mediaKey == null || mediaDigest == null) && message != null) {
          setKeyAndDigestInvalid(
            message.mediaKey,
            message.mediaDigest,
          );
        }

        if ((mediaKey == null || mediaDigest == null) &&
            transcriptMessage != null) {
          setKeyAndDigestInvalid(
            transcriptMessage.mediaKey,
            transcriptMessage.mediaDigest,
          );
        }

        final attachmentDownloadJob = _AttachmentDownloadJob(
          path: path,
          url: response.data.viewUrl!,
          keys: mediaKey != null
              ? await base64DecodeWithIsolate(mediaKey!)
              : null,
          digest: mediaDigest != null
              ? await base64DecodeWithIsolate(mediaDigest!)
              : null,
        );

        _setAttachmentJob(messageId, attachmentDownloadJob);

        await attachmentDownloadJob
            .download((int count, int total) => notifyListeners());

        final fileSize = await file.length();

        if (attachmentMessage != null) {
          final content = await jsonEncodeWithIsolate(AttachmentExtra(
            attachmentId: response.data.attachmentId,
            messageId: messageId,
            createdAt: response.data.createdAt,
            shareable: shareable,
          ).toJson());

          await _messageDao.updateMessageContent(messageId, content);
        }

        if (message != null && transcriptMessage != null) {
          final transcriptPath = convertAbsolutePath(
            category: message.category,
            fileName: file.pathBasename,
            messageId: messageId,
            isTranscript: true,
          );

          await file.copy(transcriptPath);
        }

        await _messageDao.updateMedia(
          messageId: messageId,
          path: file.path,
          mediaSize: fileSize,
          mediaStatus: MediaStatus.done,
        );

        await _updateTranscriptMessageStatus(messageId);
      }
    } catch (er) {
      e(er.toString());
      if (file.existsSync()) await file.delete();
      await _messageDao.updateMediaStatus(messageId, MediaStatus.canceled);
    } finally {
      await removeAttachmentJob(messageId);
    }
  }

  Future<AttachmentResult?> uploadAttachment(
    File file,
    String messageId,
    String category, {
    String? transcriptId,
  }) async {
    assert(!_hasAttachmentJob(messageId));
    await _messageDao.updateMediaStatus(messageId, MediaStatus.pending);

    try {
      final response = await _client.attachmentApi.postAttachment();
      if (response.data.uploadUrl == null) throw Error();
      if (transcriptId == null && await isNotPending(messageId)) return null;

      List<int>? keys;
      List<int>? iv;

      if (category.isSignal || category.isEncrypted) {
        keys = generateRandomKey(64);
        iv = generateRandomKey(16);
      }

      final attachmentUploadJob = _AttachmentUploadJob(
        path: file.absolute.path,
        url: response.data.uploadUrl!,
        keys: keys,
        iv: iv,
      );

      _setAttachmentJob(messageId, attachmentUploadJob);

      final digest = await attachmentUploadJob
          .upload((int count, int total) => notifyListeners());
      await _messageDao.updateMediaStatus(messageId, MediaStatus.done);
      return AttachmentResult(
          response.data.attachmentId,
          category.isSignal || category.isEncrypted
              ? await base64EncodeWithIsolate(keys!)
              : null,
          category.isSignal || category.isEncrypted
              ? await base64EncodeWithIsolate(digest!)
              : null,
          response.data.createdAt);
    } catch (error, s) {
      w('upload failed error: $error, $s');
      showToastFailed(ToastError.builder(
          (context) => context.l10n.errorUploadAttachmentFailed));
      await _messageDao.updateMediaStatus(messageId, MediaStatus.canceled);
      return null;
    } finally {
      await removeAttachmentJob(messageId);
    }
  }

  Future<bool> isNotPending(String messageId) =>
      _messageDao.hasMediaStatus(messageId, MediaStatus.pending, true);

  String getAttachmentDirectoryPath(String category, String conversationId) {
    assert(category.isAttachment);
    String path;
    if (category.isImage) {
      path = getImagesPath(conversationId);
    } else if (category.isVideo) {
      path = getVideosPath(conversationId);
    } else if (category.isAudio) {
      path = getAudiosPath(conversationId);
    } else {
      path = getFilesPath(conversationId);
    }
    return path;
  }

  String convertAbsolutePath({
    String? category,
    required String? fileName,
    String? conversationId,
    String? messageId,
    bool isTranscript = false,
  }) {
    if (fileName?.trim().isEmpty ?? true) return '';
    if (isTranscript) {
      var name = '$messageId${fileName!.fileExtension}';
      if (messageId == null) {
        name = fileName;
      }
      return p.join(transcriptPath, name);
    }
    if (fileName?.startsWith(mixinDocumentsDirectory.path) == true) {
      return fileName!;
    }
    assert(conversationId != null);
    assert(category != null);
    return p.join(
        getAttachmentDirectoryPath(category!, conversationId!), fileName);
  }

  File getAttachmentFile(
    String category,
    String? conversationId,
    String messageId,
    String? mediaName, {
    String? mimeType,
    bool isTranscript = false,
  }) {
    final path = isTranscript
        ? transcriptPath
        : getAttachmentDirectoryPath(category, conversationId!);
    String suffix;
    if (category.isImage) {
      if (_equalsIgnoreCase(mimeType, 'image/png')) {
        suffix = '.png';
      } else if (_equalsIgnoreCase(mimeType, 'image/gif')) {
        suffix = '.gif';
      } else if (_equalsIgnoreCase(mimeType, 'image/webp')) {
        suffix = '.webp';
      } else {
        suffix = '.jpg';
      }
    } else if (category.isVideo) {
      suffix = '.mp4';
    } else if (category.isAudio) {
      suffix = '.ogg';
    } else {
      suffix = mediaName?.fileExtension ?? '';
    }
    return File(p.join(path, '$messageId$suffix'));
  }

  bool _equalsIgnoreCase(String? string1, String? string2) =>
      string1?.toLowerCase() == string2?.toLowerCase();

  String getImagesPath(String conversationId) =>
      p.join(mediaPath, 'Images', conversationId);

  String getVideosPath(String conversationId) =>
      p.join(mediaPath, 'Videos', conversationId);

  String getAudiosPath(String conversationId) =>
      p.join(mediaPath, 'Audios', conversationId);

  String getFilesPath(String conversationId) =>
      p.join(mediaPath, 'Files', conversationId);

  static AttachmentUtil init(
    Client client,
    MessageDao messageDao,
    TranscriptMessageDao transcriptMessageDao,
    String identityNumber,
  ) {
    final documentDirectory = mixinDocumentsDirectory;
    final mediaDirectory =
        File(p.join(documentDirectory.path, identityNumber, 'Media'));
    return AttachmentUtil(
      client,
      messageDao,
      transcriptMessageDao,
      mediaDirectory.path,
    );
  }

  bool _hasAttachmentJob(String messageId) =>
      _attachmentJob.containsKey(messageId);

  void _setAttachmentJob(String messageId, _AttachmentJobBase job) {
    _attachmentJob[messageId] = job;
    if (job is _AttachmentDownloadJob) {
      DownloadKeyValue.instance.addMessageId(messageId);
    }
  }

  Future<void> removeAttachmentJob(String messageId) async {
    await DownloadKeyValue.instance.removeMessageId(messageId);
    _attachmentJob[messageId]?.cancel();
    _attachmentJob.remove(messageId);
  }

  Future<bool> cancelProgressAttachmentJob(String messageId) async {
    await _messageDao.updateMediaStatus(messageId, MediaStatus.canceled);
    await DownloadKeyValue.instance.removeMessageId(messageId);
    if (!_hasAttachmentJob(messageId)) return false;
    _attachmentJob[messageId]?.cancel();
    _attachmentJob.remove(messageId);
    return true;
  }

  double getAttachmentProgress(String messageId) =>
      _attachmentJob[messageId]?.progress ?? 0;

  Future<bool> syncMessageMedia(String messageId) async {
    Future<bool> fromMessage() async {
      if (await _messageDao.messageHasMediaStatus(
          messageId, MediaStatus.done)) {
        final message = await _messageDao.findMessageByMessageId(messageId);
        final path = convertAbsolutePath(
          category: message!.category,
          fileName: message.mediaUrl,
          conversationId: message.conversationId,
          messageId: messageId,
        );
        final transcriptPath = convertAbsolutePath(
          category: message.category,
          fileName: message.mediaUrl,
          messageId: messageId,
          isTranscript: true,
        );

        await File(path).copy(transcriptPath);

        await _messageDao.syncMessageMedia(messageId);
        return true;
      }

      return false;
    }

    Future<bool> fromOtherTranscript() async {
      final done = _messageDao.transcriptMessageHasMediaStatus(
        messageId,
        MediaStatus.done,
      );
      final notDone = _messageDao.transcriptMessageHasMediaStatus(
        messageId,
        MediaStatus.done,
        true,
      );
      if (await done && await notDone) {
        await _messageDao.syncMessageMedia(messageId);
        return true;
      }

      return false;
    }

    final result = await Future.wait([
      fromMessage(),
      fromOtherTranscript(),
    ]);
    return result.any((result) => result);
  }

  Future _updateTranscriptMessageStatus(String messageId) async {
    final transcriptIds = (await _transcriptMessageDao
            .transcriptMessageByMessageId(messageId, maxLimit)
            .get())
        .map((e) => e.transcriptId);
    await Future.forEach<String>(transcriptIds, (transcriptId) async {
      final list = await _transcriptMessageDao
          .transcriptMessageByTranscriptId(transcriptId)
          .get();
      final attachmentList =
          list.where((element) => element.category.isAttachment);

      if (attachmentList.isEmpty) return;

      final status = attachmentList
              .every((element) => element.mediaStatus == MediaStatus.done)
          ? MediaStatus.done
          : MediaStatus.canceled;
      await _messageDao.updateMediaStatus(transcriptId, status);
    });
  }
}

class AttachmentResult {
  AttachmentResult(this.attachmentId, this.keys, this.digest, this.createdAt);

  final String attachmentId;
  final String? keys;
  final String? digest;
  final String? createdAt;
}
