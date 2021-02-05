import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:mime/mime.dart';

Future<file_selector.XFile> selectFile() async {
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
      [
        'video/mpeg',
        'video/mp4',
        'video/quicktime',
        'video/webm',
      ].contains(mimeType?.toLowerCase()) ||
      {'mkv', 'avi'}.contains(extensionFromMime(mimeType));
}
