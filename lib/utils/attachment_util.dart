import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/load_balancer_utils.dart';
import '../crypto/attachment/crypto_encryptor.dart';
import 'crypto_util.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/dao/messages_dao.dart';
import '../db/extension/message_category.dart';
import '../enum/media_status.dart';
import '../enum/message_category.dart';

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
        );
        await file.create(recursive: true);
        final out = file.openWrite();

        try {
          await httpResponse.pipe(out);

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

  Future<AttachmentResult?> uploadAttachment(File file, String messageId, MessageCategory category) async {
    try {
      final response = await _client.attachmentApi.postAttachment();
      if (response.data.uploadUrl != null) {
        final fileStream = file.openRead();

        final fileLength = await file.length();
        final int totalBytes = (16 + (((fileLength / 16) +1) * 16) + 32).toInt();

        final request =
            await _attachmentClient.putUrl(Uri.parse(response.data.uploadUrl!));

        request.headers
          ..add(HttpHeaders.contentTypeHeader, 'application/octet-stream')
          ..add(HttpHeaders.connectionHeader, 'close')
          ..add(HttpHeaders.contentLengthHeader, totalBytes)
          ..add('x-amz-acl', 'public-read');

        var byteCount = 0;

        final List<int>? key;
        if (category.isSignal) {
          key = generateRandomKey(64);
        } else {
          key = null;
        }

        CryptoEncryptor? encryptor;
        List<int>? digest = null;
        await request.addStream(fileStream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              if (key != null && encryptor == null) {
                encryptor = CryptoEncryptor(sink, key);
              }
              byteCount += data.length;
              // upload progress
              debugPrint('$byteCount / $totalBytes');
              if (encryptor != null) {
                encryptor?.process(Uint8List.fromList(data));
              } else {
                sink.add(data);
              }
            },
            handleError: (error, stack, sink) {
              debugPrint('uploadAttachment error: $error');
            },
            handleDone: (sink) {
              if (encryptor != null) {
                digest = encryptor?.close();
              } else {
                sink.close();
              }
            },
          ),
        ));

        final httpResponse = await request.close();
        debugPrint('uploadAttachment httpResponse: ${httpResponse.statusCode}');
        if (httpResponse.statusCode == 200) {
          await _messagesDao.updateMediaStatus(MediaStatus.done, messageId);
          return AttachmentResult(response.data.attachmentId, await base64EncodeWithIsolate(key!), await base64EncodeWithIsolate(digest!));
        } else {
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

  File getAttachmentFile(
      MessageCategory category, String conversationId, String messageId) {
    assert(category.isAttachment);
    String? path;
    if (category.isImage) {
      path = getImagesPath(conversationId);
    } else if (category.isVideo) {
      path = getVideosPath(conversationId);
    } else if (category.isAudio) {
      path = getAudiosPath(conversationId);
    } else {
      path = getFilesPath(conversationId);
    }
    return File(p.join(path, messageId));
  }

  File _getAttachmentFile({
    required String messageId,
    required String conversationId,
    required MessageCategory category,
  }) =>
      getAttachmentFile(category, conversationId, messageId);

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
