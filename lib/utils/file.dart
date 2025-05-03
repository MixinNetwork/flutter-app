import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/cupertino.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'extension/extension.dart';
import 'logger.dart';

Future<List<XFile>> selectFiles() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // Use file_selector for desktop platforms.
    // because file_selector has better localizations.
    final files = await file_selector.openFiles();
    if (files.isEmpty) return const [];
    return files.map((xFile) => xFile.withMineType()).toList();
  } else {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) {
      return const [];
    }
    return result.paths.nonNulls
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
  final targetName = (suggestName ?? file).pathBasename;

  d('saveFileToSystem: $file, $targetName');

  final mineType = lookupMimeType(file);
  final extension = p.extension(targetName);

  var path =
      (await file_selector.getSaveLocation(
        confirmButtonText: context.l10n.save,
        suggestedName: targetName,
        acceptedTypeGroups: [
          if (Platform.isWindows)
            file_selector.XTypeGroup(
              label: mineType,
              extensions: [extension],
              mimeTypes: [if (mineType != null) mineType],
            ),
        ],
      ))?.path;
  if (path == null || path.isEmpty) {
    return false;
  }
  if (Platform.isWindows && !path.endsWith(extension)) {
    path = path + extension;
  }
  d('copy file to $path');
  await File(file).copy(path);
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

Directory get mixinLogDirectory =>
    Directory(p.join(mixinDocumentsDirectory.path, 'log'));

Future<void> initMixinDocumentsDirectory() async {
  if (Platform.isLinux) {
    // https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap08.html
    final home = Platform.environment['HOME'];
    assert(home != null, 'failed to get HOME environment.');
    mixinDocumentsDirectory = Directory(p.join(home!, '.mixin'));
    return;
  }
  if (Platform.isWindows) {
    mixinDocumentsDirectory = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'Mixin'),
    );
    return;
  }
  mixinDocumentsDirectory = await getApplicationDocumentsDirectory();
}

enum TempFileType {
  pasteboardImage('mixin_paste_board_image', '.png'),
  editImage('image_edit', '.png'),
  voiceRecord('voice_record', '.ogg'),
  logZip('log', '.zip'),
  // video thumbnail
  thumbnail('thumbnail', '.png');

  const TempFileType(this.prefix, this.suffix);

  final String prefix;
  final String suffix;
}

Future<String> generateTempFilePath(TempFileType type) async {
  final tempDir = await getTemporaryDirectory();
  return p.join(
    tempDir.path,
    '${type.prefix}_${const Uuid().v4()}${type.suffix}',
  );
}

Future<File?> saveBytesToTempFile(Uint8List bytes, TempFileType type) async {
  try {
    final file = File(await generateTempFilePath(type));
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

void renameFileWithTime(String path, DateTime time) {
  final file = File(path);
  if (!file.existsSync()) return;
  final newName = '${file.path}.${time.toIso8601String()}';
  file.renameSync(newName);
}
