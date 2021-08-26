import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/cupertino.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'extension/extension.dart';
import 'logger.dart';

Future<List<XFile>> selectFiles() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // Use file_selector for desktop platforms.
    // because file_selector has better localizations.
    final files = await file_selector.openFiles();
    if (files.isEmpty) return const [];
    return files
        .map((xFile) => file_selector.XFile(
              xFile.path,
              mimeType: xFile.mimeType ?? lookupMimeType(xFile.path),
              name: xFile.name,
            ))
        .toList();
  } else {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) {
      return const [];
    }
    return result.paths
        .whereNotNull()
        .map((e) => XFile(e, mimeType: lookupMimeType(e)))
        .toList();
  }
}

/// Copy [file] to user file system.
/// TODO: support Android/iOS.
Future<bool> saveFileToSystem(
  BuildContext context,
  String file, {
  String? suggestName,
}) async {
  final path = await file_selector.getSavePath(
    confirmButtonText: context.l10n.save,
    suggestedName: suggestName ?? p.basename(file),
  );
  if (path?.isEmpty ?? true) {
    return false;
  }
  await File(file).copy(path!);
  return true;
}

Future<int> getTotalSizeOfFile(String path) async {
  final file = File(path);
  if (file.existsSync()) return file.length();
  final directory = Directory(path);
  if (directory.existsSync()) {
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

late Directory mixinDocumentsDirectory;

Future<void> initMixinDocumentsDirectory() async {
  if (Platform.isLinux) {
    // https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap08.html
    final home = Platform.environment['HOME'];
    assert(home != null, 'failed to get HOME environment.');
    mixinDocumentsDirectory = Directory(p.join(home!, '.mixin'));
    return;
  }
  mixinDocumentsDirectory = await getApplicationDocumentsDirectory();
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
    if (file.existsSync()) {
      await file.delete();
    }
    await file.writeAsBytes(bytes);
    return file;
  } catch (error, stack) {
    e('failed to save bytes to temp file. $error $stack');
    return null;
  }
}
