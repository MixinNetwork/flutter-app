import 'dart:io';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:mime/mime.dart';

Future<file_selector.XFile?> selectFile() async {
  final xFile = await file_selector.openFile();
  if (xFile == null) return null;
  return file_selector.XFile(
    xFile.path,
    mimeType: xFile.mimeType ?? lookupMimeType(xFile.path),
    name: xFile.name,
  );
}

extension XFileExtension on file_selector.XFile {
  bool get isImage => {
        'image/jpeg',
        'image/png',
        'image/bmp',
        'image/webp',
      }.contains(mimeType?.toLowerCase());

  bool get isVideo =>
      mimeType != null &&
      ([
            'video/mpeg',
            'video/mp4',
            'video/quicktime',
            'video/webm',
          ].contains(mimeType?.toLowerCase()) ||
          {'mkv', 'avi'}.contains(extensionFromMime(mimeType!)));
}

Future<int> getTotalSizeOfFile(String path) async {
  final file = File(path);
  if (await file.exists())
    return await file.length();
  final directory = Directory(path);
  if (await directory.exists()) {
    List<FileSystemEntity> children;
    try {
      children = await directory.list().toList();
    } catch (e) {
      children = [];
    }
    var total = 0;
    for (final child in children) {
      total += await getTotalSizeOfFile(child.path);
    }
    return total;
  }
  return 0;
}
