import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:rxdart/rxdart.dart';

import '../ui/home/bloc/conversation_cubit.dart';
import '../ui/home/chat/files_preview.dart';
import '../widgets/dialog.dart';
import '../widgets/toast.dart';
import 'extension/extension.dart';
import 'file.dart';

export 'package:mixin_logger/mixin_logger.dart';

Future<void> showShareLogDialog(
  BuildContext context, {
  required ConversationState conversation,
}) async {
  final event = await showConfirmMixinDialog(
    context,
    'shared log',
    description: 'share log to ${conversation.name}',
  );
  if (event != DialogEvent.positive) {
    return;
  }
  try {
    showToastLoading();
    final zipPath = await generateTempFilePath(TempFileType.logZip);
    await compute(_createZipFile, [mixinLogDirectory.path, zipPath]);
    final file = File(zipPath);
    unawaited(showFilesPreviewDialog(context, [file.xFile]));
  } catch (error, stackTrace) {
    e('showShareLogDialog', error, stackTrace);
    showToastFailed(error);
  } finally {
    Toast.dismiss();
  }
}

Future<void> _createZipFile(List<String> paths) async {
  i('createZipFile: $paths');
  final dir = paths.first;
  final zipPath = paths[1];
  final files = await Directory(dir).list().whereType<File>().toList();
  final encoder = ZipFileEncoder()..create(zipPath);
  for (final file in files) {
    await encoder.addFile(file);
  }
  encoder.close();
}
