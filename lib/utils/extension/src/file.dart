part of '../extension.dart';

extension FileExtension on File {
  file_selector.XFile get xFile => file_selector.XFile(
        path,
        mimeType: lookupMimeType(path),
        name: basename(path),
      );
}

extension XFileExtension on file_selector.XFile {
  bool get isImage => {
        'image/jpeg',
        'image/png',
        'image/bmp',
        'image/webp',
        'image/gif',
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

extension FileRelativePath on File {
  String get pathBasename => path.pathBasename;
  String get fileExtension => path.fileExtension;
}

extension StringPathRelativePath on String {
  String get pathBasename => basename(this);
  String get fileExtension => extension(this);
}
