import 'dart:io';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:cross_file/cross_file.dart';
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

  Future<String> encodeBlurHash() async => _encodeBlurHash(path);
}

Future<String> _encodeBlurHash(String path) async {
  final fileImage = ResizeImage(FileImage(File(path)), width: 100, height: 100);
  final image = await fileImage.toImage();
  final data = Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: (await image.toBytes())!.buffer,
  );
  return BlurHash.encode(data).hash;
}

extension XFileExtension on XFile {
  bool get isImage => {
        'image/jpeg',
        'image/png',
        'image/bmp',
        'image/webp',
        'image/gif',
      }.contains(mimeType?.toLowerCase());

  bool get isGif => mimeType?.toLowerCase() == 'image/gif';

  bool get isVideo =>
      mimeType != null &&
      ([
            'video/mpeg',
            'video/mp4',
            'video/quicktime',
            'video/webm',
          ].contains(mimeType?.toLowerCase()) ||
          {'mkv', 'avi'}.contains(extensionFromMime(mimeType!)));

  bool get isStickerSupport => {
        'image/gif',
        'image/png',
        'image/webp',
        'image/jpeg',
      }.contains(mimeType?.toLowerCase());

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

  String get pathBasenameWithoutExtension => basenameWithoutExtension(this);

  String get fileExtension => extension(this);
}
