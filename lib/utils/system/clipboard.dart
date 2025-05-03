import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter/cupertino.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../widgets/toast.dart';
import '../file.dart';

Future<Iterable<File>> getClipboardFiles() async {
  final reader = await SystemClipboard.instance?.read();

  if (reader == null) {
    w('clipboard reader is null');
    return [];
  }

  final fileReaders = reader.items.where(
    (item) => item.canProvide(Formats.fileUri),
  );

  if (fileReaders.isNotEmpty) {
    final uris = await Future.wait(
      fileReaders.map((item) => item.readValue(Formats.fileUri)),
    );

    final files = uris.nonNulls
        .map((e) => e.toFilePath(windows: Platform.isWindows))
        .map(File.new)
        .where((element) => element.existsSync());
    if (files.isNotEmpty) return files;
  }

  final list = await Future.wait(
    reader.items
        .map(
          (reader) => (
            reader,
            reader.getFormats([
              Formats.jpeg,
              Formats.png,
              Formats.gif,
              Formats.webp,
              Formats.bmp,
            ]).whereType<FileFormat>(),
          ),
        )
        .where((element) => element.$2.isNotEmpty)
        .map((item) async {
          final (reader, formats) = item;

          var imageBytes = await reader.readFile(formats.firstOrNull!);
          if (imageBytes == null) return null;

          if (Platform.isWindows) {
            final image = await decodeImageFromList(imageBytes);
            final data = await image.toByteData(format: ImageByteFormat.png);
            if (data == null) return null;
            imageBytes = Uint8List.view(data.buffer);
          }

          return saveBytesToTempFile(imageBytes, TempFileType.pasteboardImage);
        }),
  );

  return list.nonNulls;
}

Future<void> copyFile(String? filePath) async {
  if (filePath == null || filePath.isEmpty) {
    return showToastFailed(null);
  }
  try {
    final dataWriterItem =
        DataWriterItem()..add(Formats.fileUri(Uri.file(filePath)));

    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return showToastFailed(null);
    }
    await clipboard.write([dataWriterItem]);
  } catch (error, stackTrace) {
    e('copy file failed: $error\n$stackTrace');
    showToastFailed(error);
    return;
  }
  showToastSuccessful();
}

extension _ReadValue on DataReader {
  Future<Uint8List?>? readFile(FileFormat format) {
    final c = Completer<Uint8List?>();
    final progress = getFile(format, (file) async {
      try {
        final all = await file.readAll();
        c.complete(all);
      } catch (e) {
        c.completeError(e);
      }
    }, onError: c.completeError);
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }
}
