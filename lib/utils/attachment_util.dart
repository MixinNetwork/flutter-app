import 'dart:io';

import 'package:flutter_app/db/mixin_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/db/extension/message_category.dart';

// ignore: prefer_generic_function_type_aliases
typedef void OnDownloadProgressCallback(int receivedBytes, int totalBytes);
// ignore: prefer_generic_function_type_aliases
typedef void OnUploadProgressCallback(int sentBytes, int totalBytes);

class AttachmentUtil {
  AttachmentUtil(this.mediaPath) {
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
  }

  final String mediaPath;
  HttpClient _client;

  void downloadAttachment(Message message) {
    // todo url
    _client
        .getUrl(Uri.parse(''))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(_getAttachmentFile(message).openWrite()));
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

  // ignore: unused_element
  String _getVideosPath(String conversationId) {
    return p.join(mediaPath, 'Videos', conversationId);
  }

  // ignore: unused_element
  String _getAudiosPath(String conversationId) {
    return p.join(mediaPath, 'Audios', conversationId);
  }

  // ignore: unused_element
  String _getFilesPath(String conversationId) {
    return p.join(mediaPath, 'Files', conversationId);
  }

  static Future<AttachmentUtil> init(String identityNumber) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    final mediaDirectory =
        File(p.join(documentDirectory.path, identityNumber, 'Media'));
    return AttachmentUtil(mediaDirectory.path);
  }
}
