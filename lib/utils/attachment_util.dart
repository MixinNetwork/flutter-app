import 'dart:io';

import 'package:flutter_app/db/mixin_database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/db/extension/message_category.dart';

// ignore: prefer_generic_function_type_aliases
typedef void OnDownloadProgressCallback(int receivedBytes, int totalBytes);
// ignore: prefer_generic_function_type_aliases
typedef void OnUploadProgressCallback(int sentBytes, int totalBytes);

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
    if (response.data != null) {
      await _attachmentClient
          .getUrl(Uri.parse(response.data.viewUrl))
          .then((HttpClientRequest request) => request.close())
          .then((HttpClientResponse response) async {
        final file = _getAttachmentFile(message);
        await file.create(recursive: true);
        await response.pipe(file.openWrite());
      });
    }
  }

  void uploadAttachment(Message message) {}

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
