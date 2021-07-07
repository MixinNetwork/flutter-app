import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'logger.dart';

Future<List<file_selector.XFile>> selectFiles() async {
  final files = await file_selector.openFiles();
  if (files.isEmpty) return const [];
  return files
      .map((xFile) => file_selector.XFile(
            xFile.path,
            mimeType: xFile.mimeType ?? lookupMimeType(xFile.path),
            name: xFile.name,
          ))
      .toList();
}

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
  if (await file.exists()) return file.length();
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

Future<Directory> getMixinDocumentsDirectory() {
  if (Platform.isLinux) {
    // https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap08.html
    final home = Platform.environment['HOME'];
    assert(home != null, 'failed to get HOME environment.');
    return Future.value(Directory(p.join(home!, '.mixin')));
  }
  return getApplicationDocumentsDirectory();
}

Future<File?> saveBytesToTempFile(
  Uint8List bytes,
  String prefix, [
  String? suffix,
]) async {
  final tempDir = await getTemporaryDirectory();

  try {
    final file = File(p.join(tempDir.path,
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}$suffix'));
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(bytes);
    return file;
  } catch (error, stack) {
    e('failed to save bytes to temp file. $error $stack');
    return null;
  }
}
