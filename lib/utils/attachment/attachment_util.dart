import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../crypto/attachment/crypto_attachment.dart';
import '../../db/dao/message_dao.dart';
import '../../db/extension/message_category.dart';
import '../../enum/media_status.dart';
import '../crypto_util.dart';
import '../file.dart';
import '../load_balancer_utils.dart';
import '../logger.dart';

part 'attachment_download_job.dart';

part 'attachment_upload_job.dart';

final _dio = Dio(BaseOptions(
  connectTimeout: 150 * 1000,
  receiveTimeout: 150 * 1000,
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
    if (total == 0 && current == 0) return 0;
    return min(current / total, 1);
  }
}

class AttachmentUtil extends ChangeNotifier {
  AttachmentUtil(this._client, this._messageDao, this.mediaPath) {
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    };
  }

  final String mediaPath;
  final MessageDao _messageDao;
  final Client _client;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: 150 * 1000,
      receiveTimeout: 150 * 1000,
    ),
  );

  final _attachmentJob = <String, _AttachmentJobBase>{};

  Future<String?> downloadAttachment({
    required String messageId,
    required String content,
    required String conversationId,
    required String category,
    AttachmentMessage? attachmentMessage,
  }) async {
    assert(_attachmentJob[messageId] == null);
    await _messageDao.updateMediaStatus(MediaStatus.pending, messageId);

    try {
      final response = await _client.attachmentApi.getAttachment(content);
      d('download ${response.data.viewUrl}');

      if (await _isNotPending(messageId)) return null;

      if (response.data.viewUrl != null) {
        final file = getAttachmentFile(
          category,
          conversationId,
          messageId,
          mimeType: attachmentMessage?.mimeType,
        );

        try {
          String? mediaKey;
          String? mediaDigest;

          if (category.isSignal) {
            mediaKey = attachmentMessage?.key;
            mediaDigest = attachmentMessage?.digest;
            if (mediaKey == null || mediaDigest == null) {
              final message =
                  await _messageDao.findMessageByMessageId(messageId);
              if (message != null) {
                mediaKey = message.mediaKey;
                mediaDigest = message.mediaDigest;
              }
              if (mediaKey == null || mediaDigest == null) {
                throw InvalidKeyException(
                    'decrypt attachment key: ${attachmentMessage?.key}, digest: ${attachmentMessage?.digest}');
              }
            }
          }

          final attachmentDownloadJob = _AttachmentDownloadJob(
            path: file.absolute.path,
            url: response.data.viewUrl!,
            keys: mediaKey != null
                ? await base64DecodeWithIsolate(mediaKey)
                : null,
            digest: mediaDigest != null
                ? await base64DecodeWithIsolate(mediaDigest)
                : null,
          );

          _attachmentJob[messageId] = attachmentDownloadJob;

          await attachmentDownloadJob
              .download((int count, int total) => notifyListeners());

          final fileSize = await file.length();

          if (attachmentMessage != null) {
            final encoded =
                await jsonBase64EncodeWithIsolate(attachmentMessage);
            await _messageDao.updateMessageContent(messageId, encoded);
          }

          await _messageDao.updateMediaMessageUrl(file.path, messageId);
          await _messageDao.updateMediaSize(fileSize, messageId);
          await _messageDao.updateMediaStatus(MediaStatus.done, messageId);
        } catch (err) {
          e(err.toString());
          await _messageDao.updateMediaStatusToCanceled(messageId);
        }
        return file.absolute.path;
      }
    } catch (er) {
      e(er.toString());
      await _messageDao.updateMediaStatusToCanceled(messageId);
    } finally {
      _attachmentJob[messageId]?.cancel();
      _attachmentJob.remove(messageId);
    }
  }

  Future<AttachmentResult?> uploadAttachment(
      File file, String messageId, String category) async {
    assert(_attachmentJob[messageId] == null);
    await _messageDao.updateMediaStatus(MediaStatus.pending, messageId);

    try {
      final response = await _client.attachmentApi.postAttachment();
      if (response.data.uploadUrl == null) throw Error();
      if (await _isNotPending(messageId)) return null;

      List<int>? keys;
      List<int>? iv;

      if (category.isSignal) {
        keys = generateRandomKey(64);
        iv = generateRandomKey(16);
      }

      final attachmentUploadJob = _AttachmentUploadJob(
        path: file.absolute.path,
        url: response.data.uploadUrl!,
        keys: keys,
        iv: iv,
      );

      _attachmentJob[messageId] = attachmentUploadJob;
      final digest = await attachmentUploadJob
          .upload((int count, int total) => notifyListeners());
      await _messageDao.updateMediaStatus(MediaStatus.done, messageId);
      return AttachmentResult(
          response.data.attachmentId,
          category.isSignal ? await base64EncodeWithIsolate(keys!) : null,
          category.isSignal ? await base64EncodeWithIsolate(digest!) : null,
          response.data.createdAt);
    } catch (e) {
      w(e.toString());
      await _messageDao.updateMediaStatusToCanceled(messageId);
      return null;
    } finally {
      _attachmentJob[messageId]?.cancel();
      _attachmentJob.remove(messageId);
    }
  }

  Future<bool> _isNotPending(String messageId) async =>
      MediaStatus.pending !=
      await _messageDao.mediaStatus(messageId).getSingleOrNull();

  void deleteCryptoTmpFile(String category, File file) {
    if (category.isSignal) {
      file.delete();
    }
  }

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

  String convertAbsolutePath(
      String category, String conversationId, String? fileName) {
    if (fileName?.trim().isEmpty ?? true) return '';
    assert(category.isAttachment);
    if (fileName?.startsWith(mixinDocumentsDirectory.path) == true) {
      return fileName!;
    }
    return p.join(
        getAttachmentDirectoryPath(category, conversationId), fileName);
  }

  File getAttachmentFile(
      String category, String conversationId, String messageId,
      {String? mimeType}) {
    final path = getAttachmentDirectoryPath(category, conversationId);
    String suffix;
    if (category.isImage) {
      if (_equalsIgnoreCase(mimeType, 'image/png')) {
        suffix = 'png';
      } else if (_equalsIgnoreCase(mimeType, 'image/gif')) {
        suffix = 'gif';
      } else if (_equalsIgnoreCase(mimeType, 'image/webp')) {
        suffix = 'webp';
      } else {
        suffix = 'jpg';
      }
    } else if (category.isVideo) {
      suffix = 'mp4';
    } else if (category.isAudio) {
      suffix = 'ogg';
    } else {
      assert(mimeType != null);
      suffix = extensionFromMime(mimeType!);
    }
    return File(p.join(path, '$messageId.$suffix'));
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
      Client client, MessageDao messageDao, String identityNumber) {
    final documentDirectory = mixinDocumentsDirectory;
    final mediaDirectory =
        File(p.join(documentDirectory.path, identityNumber, 'Media'));
    return AttachmentUtil(client, messageDao, mediaDirectory.path);
  }

  Future<bool> cancelProgressAttachmentJob(String messageId) async {
    await _messageDao.updateMediaStatus(MediaStatus.canceled, messageId);
    if (_attachmentJob[messageId] == null) return false;
    _attachmentJob[messageId]?.cancel();
    _attachmentJob.remove(messageId);
    return true;
  }

  double getAttachmentProgress(String messageId) =>
      _attachmentJob[messageId]?.progress ?? 0;
}

class AttachmentResult {
  AttachmentResult(this.attachmentId, this.keys, this.digest, this.createdAt);

  final String attachmentId;
  final String? keys;
  final String? digest;
  final String? createdAt;
}
