import 'dart:io';

import 'package:flutter_app/db/mixin_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentUtil {
  AttachmentUtil(this.mediaPath);

  final String mediaPath;

  void downloadAttachment(Message message) {

  }

  void uploadAttachment(Message message) {

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

  static Future<AttachmentUtil> init(String identityNumber) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    final mediaDirectory =
        File(p.join(documentDirectory.path, identityNumber, 'Media'));
    return AttachmentUtil(mediaDirectory.path);
  }
}
