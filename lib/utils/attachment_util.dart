import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/attachment/crypto_attachment.dart';
import '../db/dao/messages_dao.dart';
import '../db/extension/message_category.dart';
import '../enum/media_status.dart';
import '../enum/message_category.dart';
import 'crypto_util.dart';
import 'load_balancer_utils.dart';

class AttachmentUtil {
  AttachmentUtil(this._client, this._messagesDao, this.mediaPath) {
    _attachmentClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
  }

  final String mediaPath;
  final MessagesDao _messagesDao;
  final Client _client;
  late final HttpClient _attachmentClient;

  Future<String?> downloadAttachment({
    required String messageId,
    required String content,
    required String conversationId,
    required MessageCategory category,
    String? key,
    String? digest,
    String? mimeType,
  }) async {
    await _messagesDao.updateMediaStatus(MediaStatus.pending, messageId);

    try {
      final response = await _client.attachmentApi.getAttachment(content);
      debugPrint('download ${response.data.viewUrl}');

      if (response.data.viewUrl != null) {
        final request =
            await _attachmentClient.getUrl(Uri.parse(response.data.viewUrl!));

        request.headers
            .add(HttpHeaders.contentTypeHeader, 'application/octet-stream');

        final httpResponse = await request.close();

        final file = _getAttachmentFile(
          conversationId: conversationId,
          messageId: messageId,
          category: category,
          mimeType: mimeType,
        );
        await file.create(recursive: true);
        final out = file.openWrite();

        try {
          await httpResponse.pipe(out);

          if (category.isSignal) {
            var localKey = key;
            var localDigest = digest;
            if (localKey == null || localDigest == null) {
              final message =
                  await _messagesDao.findMessageByMessageId(messageId);
              if (message != null) {
                localKey = message.mediaKey;
                localDigest = message.mediaDigest;
              }
              if (localKey == null || localDigest == null) {
                throw InvalidKeyException(
                    'decrypt attachment key: $key, digest: $digest');
              }
            }
            final result = CryptoAttachment().decryptAttachment(
              file.readAsBytesSync(),
              await base64DecodeWithIsolate(localKey),
              await base64DecodeWithIsolate(localDigest),
            );
            file.writeAsBytesSync(result);
          }

          await _messagesDao.updateMediaMessageUrl(file.path, messageId);
          await _messagesDao.updateMediaSize(await file.length(), messageId);
          await _messagesDao.updateMediaStatus(MediaStatus.done, messageId);
        } catch (e) {
          await out.close();
          await file.delete();
          await _messagesDao.updateMediaStatus(MediaStatus.canceled, messageId);
        }
        return file.path;
      }
    } catch (e) {
      await _messagesDao.updateMediaStatus(MediaStatus.canceled, messageId);
    }
  }

  Future<AttachmentResult?> uploadAttachment(
      File file, String messageId, MessageCategory category) async {
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
        final request =
            await _attachmentClient.putUrl(Uri.parse(response.data.uploadUrl!));
        final totalBytes = await tmpFile.length();
        debugPrint(tmpFile.path);

        request.headers
          ..add(HttpHeaders.contentTypeHeader, 'application/octet-stream')
          ..add(HttpHeaders.connectionHeader, 'close')
          ..add(HttpHeaders.contentLengthHeader, totalBytes)
          ..add('x-amz-acl', 'public-read');

        var byteCount = 0;

        final fileStream = tmpFile.openRead();
        await request.addStream(fileStream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              byteCount += data.length;
              // upload progress
              debugPrint('$byteCount / $totalBytes');
              sink.add(data);
            },
            handleError: (error, stack, sink) {},
            handleDone: (sink) {
              sink.close();
            },
          ),
        ));

        final httpResponse = await request.close();
        if (httpResponse.statusCode == 200) {
          deleteCryptoTmpFile(category, tmpFile);
          await _messagesDao.updateMediaStatus(MediaStatus.done, messageId);
          return AttachmentResult(
              response.data.attachmentId,
              category.isSignal ? await base64EncodeWithIsolate(keys!) : null,
              category.isSignal
                  ? await base64EncodeWithIsolate(digest!)
                  : null);
        } else {
          deleteCryptoTmpFile(category, tmpFile);
          await _messagesDao.updateMediaStatus(MediaStatus.canceled, messageId);
          return null;
        }
      } else {
        await _messagesDao.updateMediaStatus(MediaStatus.canceled, messageId);
        return null;
      }
    } catch (e) {
      debugPrint(e.toString());
      await _messagesDao.updateMediaStatus(MediaStatus.canceled, messageId);
      return null;
    }
  }

  void deleteCryptoTmpFile(MessageCategory category, File file) {
    if (category.isSignal) {
      file.delete();
    }
  }

  File getAttachmentFile(
      MessageCategory category, String conversationId, String messageId,
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
    required MessageCategory category,
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
      Client client, MessagesDao messagesDao, String identityNumber) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    final mediaDirectory =
        File(p.join(documentDirectory.path, identityNumber, 'Media'));
    return AttachmentUtil(client, messagesDao, mediaDirectory.path);
  }
}

class AttachmentResult {
  AttachmentResult(this.attachmentId, this.keys, this.digest);

  final String attachmentId;
  final String? keys;
  final String? digest;
}
