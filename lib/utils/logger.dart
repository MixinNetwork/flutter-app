import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:rxdart/rxdart.dart';

import '../ui/home/chat/files_preview.dart';
import '../widgets/dialog.dart';
import '../widgets/toast.dart';
import 'extension/extension.dart';
import 'file.dart';
import 'system/memory.dart';
import 'system/package_info.dart';

export 'package:mixin_logger/mixin_logger.dart';

Future<void> dumpAppAndSystemInfoToLogger() async {
  final info = await _dumpAppAndSystemInfo();
  i('app launch:\n$info');
  setLoggerFileLeading(info);
}

String _getBuildType() {
  if (kReleaseMode) {
    return 'release';
  }
  if (kProfileMode) {
    return 'profile';
  }
  return 'debug';
}

Future<String> _dumpAppAndSystemInfo() async {
  final info = StringBuffer();
  // app info
  final packageInfo = await getPackageInfo();
  info
    ..writeln(
        'AppVersion ${packageInfo.version} BuildNumber: ${packageInfo.buildNumber}')
    ..writeln('BuildType: ${_getBuildType()}')
    ..writeln(
        'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
    ..writeln('DartRuntime: ${Platform.version}')
    ..writeln('NumberOfProcessors: ${Platform.numberOfProcessors} cores')
    ..writeln('DiskUsage: ${dumpFreeDiskSpaceToString()}');

  return info.toString();
}

Future<void> showShareLogDialog(
  BuildContext context, {
  required String conversationName,
}) async {
  final event = await showConfirmMixinDialog(
    context,
    'shared log',
    description: 'share log to $conversationName',
  );

  if (event != DialogEvent.positive) return;

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
  await encoder.close();
}
