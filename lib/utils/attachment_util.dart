import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/extension/message_category.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentUtil {
  AttachmentUtil(this._client, this._messagesDao, this._mediaPath) {
    _attachmentClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
  }

  final String _mediaPath;
  final MessagesDao _messagesDao;
  final Client _client;
  HttpClient _attachmentClient;

  void downloadAttachment(Message message) async {
    final response = await _client.attachmentApi.getAttachment(message.content);
    if (response.data != null && response.data.viewUrl != null) {
      final request =
          await _attachmentClient.getUrl(Uri.parse(response.data.viewUrl));

      request.headers
          .add(HttpHeaders.contentTypeHeader, 'application/octet-stream');

      final httpResponse = await request.close();

      var byteCount = 0;
      final totalBytes = httpResponse.contentLength;

      final file = _getAttachmentFile(message);
      await file.create(recursive: true);
      final raf = file.openSync(mode: FileMode.write);

      debugPrint('download ${Uri.parse(response.data.viewUrl)}');
      httpResponse.listen(
        (data) {
          byteCount += data.length;
          raf.writeFromSync(data);
          // download progress
          debugPrint('$byteCount / $totalBytes');
        },
        onDone: () async {
          raf.closeSync();
          await _messagesDao.updateMediaMessageUrl(file.path, message.messageId);
          await _messagesDao.updateMediaSize(file.lengthSync(), message.messageId);
          await _messagesDao.updateMediaStatus(MediaStatus.done, message.messageId);
        },
        onError: (e) async {
          raf.closeSync();
          file.deleteSync();
          await _messagesDao.updateMediaStatus(MediaStatus.canceled, message.messageId);
        },
        cancelOnError: true,
      );
    }
  }

  Future<String> uploadAttachment(File file, String messageId) async {
    final response = await _client.attachmentApi.postAttachment();
    if (response.data != null && response.data.uploadUrl != null) {
      final fileStream = file.openRead();

      final totalBytes = file.lengthSync();

      final request =
          await _attachmentClient.putUrl(Uri.parse(response.data.uploadUrl));

      request.headers
        ..add(HttpHeaders.contentTypeHeader, 'application/octet-stream')
        ..add(HttpHeaders.connectionHeader, 'close')
        ..add(HttpHeaders.contentLengthHeader, totalBytes)
        ..add('x-amz-acl', 'public-read');

      var byteCount = 0;

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
        await _messagesDao.updateMediaStatus(MediaStatus.done, messageId);
        return response.data.attachmentId;
      } else {
        await _messagesDao.updateMediaStatus(MediaStatus.canceled, messageId);
        return null;
      }
    } else {
      await _messagesDao.updateMediaStatus(MediaStatus.canceled, messageId);
      return null;
    }
  }

  File getAttachmentFile(
      MessageCategory category, String conversationId, String messageId) {
    assert(category.isAttachment);
    String path;
    if (category.isImage) {
      path = _getImagesPath(conversationId);
    } else if (category.isVideo) {
      path = _getVideosPath(conversationId);
    } else if (category.isAudio) {
      path = _getAudiosPath(conversationId);
    } else if (category.isData) {
      path = _getFilesPath(conversationId);
    }
    return File(p.join(path, messageId));
  }

  File _getAttachmentFile(Message message) => getAttachmentFile(
      message.category, message.conversationId, message.messageId);

  String _getImagesPath(String conversationId) {
    return p.join(_mediaPath, 'Images', conversationId);
  }

  String _getVideosPath(String conversationId) {
    return p.join(_mediaPath, 'Videos', conversationId);
  }

  String _getAudiosPath(String conversationId) {
    return p.join(_mediaPath, 'Audios', conversationId);
  }

  String _getFilesPath(String conversationId) {
    return p.join(_mediaPath, 'Files', conversationId);
  }

  static Future<AttachmentUtil> init(
      Client client, MessagesDao messagesDao, String identityNumber) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    final mediaDirectory =
        File(p.join(documentDirectory.path, identityNumber, 'Media'));
    return AttachmentUtil(client, messagesDao, mediaDirectory.path);
  }
}
