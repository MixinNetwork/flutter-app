import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:open_file/open_file.dart';

import '../../account/account_server.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/file.dart';
import '../../utils/logger.dart';
import '../toast.dart';

Future<void> saveAs(
  BuildContext context,
  AccountServer accountServer,
  MessageItem message,
  bool isTranscriptPage,
) async {
  final path = accountServer.convertMessageAbsolutePath(
    message,
    isTranscriptPage,
  );
  if (Platform.isAndroid || Platform.isIOS) {
    if (message.type.isImage || message.type.isVideo) {
      try {
        if (message.type.isImage) {
          await Gal.putImage(path);
        } else {
          await Gal.putVideo(path);
        }
        showToastSuccessful();
      } catch (error, stackTrace) {
        d('save file error: $error, stack: $stackTrace');
        return showToastFailed(error);
      }
    } else {
      await OpenFile.open(path);
    }
  } else {
    try {
      final result = await saveFileToSystem(
        context,
        path,
        suggestName: message.mediaName,
      );
      if (result) return showToastSuccessful();
    } catch (error, stackTrace) {
      d('save file error: $error, stack: $stackTrace');
      return showToastFailed(error);
    }
  }
}
