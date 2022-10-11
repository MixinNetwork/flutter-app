import 'dart:io';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:cross_file/cross_file.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

import '../extension.dart';

extension FileExtension on File {
  XFile get xFile => XFile(
        path,
        mimeType: lookupMimeType(path),
        name: basename(path),
      );

  Future<String?> encodeBlurHash() async {
    final image = await _getSmallImage(path);
    return BlurHash.encode(image).hash;
  }
}

Future<Image> _getSmallImage(String path) async {
  final fileImage = FileImage(File(path));
  final imageProvider = ExtendedResizeImage(fileImage, maxBytes: 128 << 10);
  final image = await imageProvider.toImage();
  return Image.fromBytes(image.width, image.height, (await image.toBytes())!);
}

extension XFileExtension on XFile {
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

  XFile withMineType() => XFile(
        path,
        mimeType: mimeType ?? lookupMimeType(path),
        name: name,
      );
}

extension FileRelativePath on File {
  String get pathBasename => path.pathBasename;

  String get fileExtension => path.fileExtension;
}

extension StringPathRelativePath on String {
  String get pathBasename => basename(this);

  String get fileExtension => extension(this);
}
