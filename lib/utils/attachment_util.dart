import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/db/extension/message_category.dart';

class AttachmentUtil {
  AttachmentUtil(this._client, this.mediaPath) {
    _attachmentClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
  }

  final String mediaPath;
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
        onDone: () {
          raf.closeSync();
        },
        onError: (e) {
          raf.closeSync();
          file.deleteSync();
        },
        cancelOnError: true,
      );
    }
  }

  void uploadAttachment(File file, String messageId) async {
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
        // todo
        debugPrint('upload done!');
      } else {
        // todo
      }
    }
  }

  File _getAttachmentFile(Message message) {
    assert(message.category.isAttachment);
    String path;
    if (message.category.isImage) {
      path = _getImagesPath(message.conversationId);
    } else if (message.category.isVideo) {
      path = _getVideosPath(message.conversationId);
    } else if (message.category.isAudio) {
      path = _getAudiosPath(message.conversationId);
    } else if (message.category.isData) {
      path = _getFilesPath(message.conversationId);
    }
    return File(p.join(path, message.messageId));
  }

  String _getImagesPath(String conversationId) {
    return p.join(mediaPath, 'Images', conversationId);
  }

  String _getVideosPath(String conversationId) {
    return p.join(mediaPath, 'Videos', conversationId);
  }

  String _getAudiosPath(String conversationId) {
    return p.join(mediaPath, 'Audios', conversationId);
  }

  String _getFilesPath(String conversationId) {
    return p.join(mediaPath, 'Files', conversationId);
  }

  static Future<AttachmentUtil> init(
      Client client, String identityNumber) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    final mediaDirectory =
        File(p.join(documentDirectory.path, identityNumber, 'Media'));
    return AttachmentUtil(client, mediaDirectory.path);
  }
}
