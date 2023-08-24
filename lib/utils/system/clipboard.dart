import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter/cupertino.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../widgets/toast.dart';
import '../extension/extension.dart';
import '../file.dart';
import '../logger.dart';

Future<Iterable<File>> getClipboardFiles() async {
  final reader = await ClipboardReader.readClipboard();

  try {
    final fileReaders =
        reader.items.where((item) => item.canProvide(Formats.fileUri));

    if (fileReaders.isNotEmpty) {
      final uris = await Future.wait(
          fileReaders.map((item) => item.readValue(Formats.fileUri)));
      final files = uris.whereNotNull().map((item) => File(item.path));
      if (files.isNotEmpty) return files;
    }
  } catch (error, stack) {
    e('Pasteboard.files: $error $stack');
  }

  Uint8List? imageBytes;
  try {
    final format = reader
        .getFormats([
          Formats.jpeg,
          Formats.png,
          Formats.gif,
          Formats.tiff,
          Formats.webp,
        ])
        .map((e) => switch (e) {
              Formats.jpeg => Formats.jpeg,
              Formats.png => Formats.png,
              Formats.gif => Formats.gif,
              Formats.tiff => Formats.tiff,
              Formats.webp => Formats.webp,
              DataFormat<Object>() => null,
            })
        .whereNotNull()
        .firstOrNull;
    if (format == null) return [];

    imageBytes = await reader.readFile(format);
  } catch (error, stack) {
    e('Pasteboard.image: $error $stack');
  }

  if (imageBytes != null) {
    if (Platform.isWindows) {
      try {
        final image = await decodeImageFromList(imageBytes);
        final data = await image.toByteData(format: ImageByteFormat.png);
        if (data == null) {
          return const [];
        }
        imageBytes = Uint8List.view(data.buffer);
      } catch (error, s) {
        e('re format image failed: $error $s');
      }
    }
    final file =
        await saveBytesToTempFile(imageBytes!, TempFileType.pasteboardImage);
    if (file != null) {
      return [file];
    }
  }

  return const [];
}

Future<void> copyFile(String? filePath) async {
  if (filePath == null || filePath.isEmpty) {
    return showToastFailed(null);
  }
  try {
    final dataWriterItem = DataWriterItem()
      ..add(Formats.fileUri(Uri.parse(filePath)));

    await ClipboardWriter.instance.write([dataWriterItem]);
  } catch (error) {
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
