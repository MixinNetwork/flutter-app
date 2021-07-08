import 'dart:async';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart' as p;

import '../blaze/vo/attachment_message.dart';
import '../crypto/attachment/crypto_attachment.dart';
import '../db/dao/message_dao.dart';
import '../db/extension/message_category.dart';
import '../enum/media_status.dart';
import 'crypto_util.dart';
import 'file.dart';
import 'load_balancer_utils.dart';
import 'logger.dart';

class AttachmentUtil {
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
  final _messageIdCancelTokenMap = <String, CancelToken?>{};

  Future<String?> downloadAttachment({
    required String messageId,
    required String content,
    required String conversationId,
    required String category,
    AttachmentMessage? attachmentMessage,
  }) async {
    assert(_messageIdCancelTokenMap[messageId] == null);
    await _messageDao.updateMediaStatus(MediaStatus.pending, messageId);

    try {
      final response = await _client.attachmentApi.getAttachment(content);
      d('download ${response.data.viewUrl}');

      if (response.data.viewUrl != null) {
        final file = _getAttachmentFile(
          conversationId: conversationId,
          messageId: messageId,
          category: category,
          mimeType: attachmentMessage?.mimeType,
        );

        try {
          _messageIdCancelTokenMap[messageId] = CancelToken();

          await _dio.downloadUri(
            Uri.parse(response.data.viewUrl!),
            file.absolute.path,
            options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/octet-stream',
              },
            ),
            cancelToken: _messageIdCancelTokenMap[messageId],
          );

          if (category.isSignal) {
            var localKey = attachmentMessage?.key;
            var localDigest = attachmentMessage?.digest;
            if (localKey == null || localDigest == null) {
              final message =
                  await _messageDao.findMessageByMessageId(messageId);
              if (message != null) {
                localKey = message.mediaKey;
                localDigest = message.mediaDigest;
              }
              if (localKey == null || localDigest == null) {
                throw InvalidKeyException(
                    'decrypt attachment key: ${attachmentMessage?.key}, digest: ${attachmentMessage?.digest}');
              }
            }
            final result = CryptoAttachment().decryptAttachment(
              file.readAsBytesSync(),
              await base64DecodeWithIsolate(localKey),
              await base64DecodeWithIsolate(localDigest),
            );
            file.writeAsBytesSync(result);
          }

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
          await _messageDao.updateMediaStatus(MediaStatus.canceled, messageId);
        }
        return file.absolute.path;
      }
    } catch (er) {
      e(er.toString());
      await _messageDao.updateMediaStatus(MediaStatus.canceled, messageId);
    } finally {
      _messageIdCancelTokenMap[messageId] = null;
    }
  }

  Future<AttachmentResult?> uploadAttachment(
      File file, String messageId, String category) async {
    assert(_messageIdCancelTokenMap[messageId] == null);
    await _messageDao.updateMediaStatus(MediaStatus.pending, messageId);

    try {
      final response = await _client.attachmentApi.postAttachment();
      if (response.data.uploadUrl != null) {
        File tmpFile;
        List<int>? keys;
        List<int>? digest;
        if (category.isSignal) {
          tmpFile = File(p.join(file.parent.path, '$messageId.tmp'));
          keys = generateRandomKey(64);
          final iv = generateRandomKey(16);
          final encrypted = CryptoAttachment()
              .encryptAttachment(file.readAsBytesSync(), keys, iv);
          final encryptedBin = encrypted.item1;
          digest = encrypted.item2;
          tmpFile.writeAsBytesSync(encryptedBin);
        } else {
          tmpFile = file;
        }

        d(tmpFile.path);

        _messageIdCancelTokenMap[messageId] = CancelToken();
        final httpResponse = await _dio.putUri(
          Uri.parse(response.data.uploadUrl!),
          data: tmpFile.openRead(),
          options: Options(
            headers: {
              HttpHeaders.contentTypeHeader: 'application/octet-stream',
              HttpHeaders.connectionHeader: 'close',
              HttpHeaders.contentLengthHeader: await tmpFile.length(),
              'x-amz-acl': 'public-read',
            },
          ),
          onSendProgress: (int count, int total) => v('$count / $total'),
          cancelToken: _messageIdCancelTokenMap[messageId],
        );

        if (httpResponse.statusCode == 200) {
          deleteCryptoTmpFile(category, tmpFile);
          await _messageDao.updateMediaStatus(MediaStatus.done, messageId);
          return AttachmentResult(
              response.data.attachmentId,
              category.isSignal ? await base64EncodeWithIsolate(keys!) : null,
              category.isSignal ? await base64EncodeWithIsolate(digest!) : null,
              response.data.createdAt);
        } else {
          deleteCryptoTmpFile(category, tmpFile);
          await _messageDao.updateMediaStatus(MediaStatus.canceled, messageId);
          return null;
        }
      } else {
        await _messageDao.updateMediaStatus(MediaStatus.canceled, messageId);
        return null;
      }
    } catch (e) {
      w(e.toString());
      await _messageDao.updateMediaStatus(MediaStatus.canceled, messageId);
      return null;
    } finally {
      _messageIdCancelTokenMap[messageId] = null;
    }
  }

  void deleteCryptoTmpFile(String category, File file) {
    if (category.isSignal) {
      file.delete();
    }
  }

  File getAttachmentFile(
      String category, String conversationId, String messageId,
      {String? mimeType}) {
    assert(category.isAttachment);
    String path;
    String suffix;
    if (category.isImage) {
      path = getImagesPath(conversationId);
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
      path = getVideosPath(conversationId);
      suffix = 'mp4';
    } else if (category.isAudio) {
      path = getAudiosPath(conversationId);
      suffix = 'ogg';
    } else {
      path = getFilesPath(conversationId);
      assert(mimeType != null);
      suffix = extensionFromMime(mimeType!);
    }
    return File(p.join(path, '$messageId.$suffix'));
  }

  bool _equalsIgnoreCase(String? string1, String? string2) =>
      string1?.toLowerCase() == string2?.toLowerCase();

  File _getAttachmentFile({
    required String messageId,
    required String conversationId,
    required String category,
    String? mimeType,
  }) =>
      getAttachmentFile(category, conversationId, messageId,
          mimeType: mimeType);

  String getImagesPath(String conversationId) =>
      p.join(mediaPath, 'Images', conversationId);

  String getVideosPath(String conversationId) =>
      p.join(mediaPath, 'Videos', conversationId);

  String getAudiosPath(String conversationId) =>
      p.join(mediaPath, 'Audios', conversationId);

  String getFilesPath(String conversationId) =>
      p.join(mediaPath, 'Files', conversationId);

  static Future<AttachmentUtil> init(
      Client client, MessageDao messageDao, String identityNumber) async {
    final documentDirectory = await getMixinDocumentsDirectory();
    final mediaDirectory =
        File(p.join(documentDirectory.path, identityNumber, 'Media'));
    return AttachmentUtil(client, messageDao, mediaDirectory.path);
  }

  bool cancelProgressAttachmentJob(String messageId) {
    if (_messageIdCancelTokenMap[messageId] == null) return false;
    _messageIdCancelTokenMap[messageId]?.cancel();
    _messageIdCancelTokenMap[messageId] = null;
    return true;
  }
}

class AttachmentResult {
  AttachmentResult(this.attachmentId, this.keys, this.digest, this.createdAt);

  final String attachmentId;
  final String? keys;
  final String? digest;
  final String? createdAt;
}
