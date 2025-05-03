import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:win32/win32.dart';

extension _String on int {
  String get bytesToGbString => (this / 1024 / 1024 / 1024).toStringAsFixed(2);
}

String dumpFreeDiskSpaceToString() {
  if (Platform.isWindows) {
    try {
      final lpDirectoryName = TEXT(r'C:\');
      final lpFreeBytesAvailableToCaller = calloc<Uint64>();
      final lpTotalNumberOfBytes = calloc<Uint64>();
      final lpTotalNumberOfFreeBytes = calloc<Uint64>();
      GetDiskFreeSpaceEx(
        lpDirectoryName,
        lpFreeBytesAvailableToCaller,
        lpTotalNumberOfBytes,
        lpTotalNumberOfFreeBytes,
      );
      final freeBytesAvailableToCaller =
          lpFreeBytesAvailableToCaller.value.bytesToGbString;
      final totalNumberOfBytes = lpTotalNumberOfBytes.value.bytesToGbString;
      final totalNumberOfFreeBytes =
          lpTotalNumberOfFreeBytes.value.bytesToGbString;

      final str =
          'freeBytesAvailableToCaller: $freeBytesAvailableToCaller GB, '
          'totalNumberOfBytes: $totalNumberOfBytes GB, '
          'totalNumberOfFreeBytes: $totalNumberOfFreeBytes GB';

      free(lpFreeBytesAvailableToCaller);
      free(lpTotalNumberOfBytes);
      free(lpTotalNumberOfFreeBytes);
      free(lpDirectoryName);
      return str;
    } catch (error, stacktrace) {
      e('failed to get disk free space. $error $stacktrace');
    }
  }
  return '';
}
