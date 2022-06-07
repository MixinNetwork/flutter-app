import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui';

import 'package:ansicolor/ansicolor.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import 'extension/extension.dart';

const kLogMode = !kReleaseMode;

enum _LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf,
}

final _verbosePen = AnsiPen()..gray();
final _debugPen = AnsiPen()..blue();
final _infoPen = AnsiPen()..green();
final _warningPen = AnsiPen()..yellow();
final _errorPen = AnsiPen()..red();
final _wtfPen = AnsiPen()..magenta();

extension _LogLevelExtension on _LogLevel {
  String get prefix {
    switch (this) {
      case _LogLevel.verbose:
        return '[V]';
      case _LogLevel.debug:
        return '[D]';
      case _LogLevel.info:
        return '[I]';
      case _LogLevel.warning:
        return '[W]';
      case _LogLevel.error:
        return '[E]';
      case _LogLevel.wtf:
        return '[WTF]';
    }
  }

  String colorize(String message) {
    switch (this) {
      case _LogLevel.verbose:
        return _verbosePen(message);
      case _LogLevel.debug:
        return _debugPen(message);
      case _LogLevel.info:
        return _infoPen(message);
      case _LogLevel.warning:
        return _warningPen(message);
      case _LogLevel.error:
        return _errorPen(message);
      case _LogLevel.wtf:
        return _wtfPen(message);
    }
  }
}

String colorizeNonAnsi(String message) {
  final ansiColorMessage =
      message.startsWith(ansiEscape) && message.endsWith(ansiDefault);

  if (!ansiColorMessage) return _debugPen(message);

  return message;
}

void v(String message) {
  _print(message, _LogLevel.verbose);
}

void d(String message) {
  _print(message, _LogLevel.debug);
}

void i(String message) {
  _print(message, _LogLevel.info);
}

void w(String message) {
  _print(message, _LogLevel.warning);
}

void e(String message) {
  _print(message, _LogLevel.error);
}

void wtf(String message) {
  _print(message, _LogLevel.wtf);
}

String _currentTimeStamp() =>
    DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());

void _print(String message, _LogLevel level) {
  final logToFile = kLogMode || level.index > _LogLevel.debug.index;
  if (logToFile) {
    LogFileManager.instance
        ?.write('${_currentTimeStamp()} ${level.prefix} $message');
  }
  if (!kLogMode) return;
  // ignore: avoid_print
  print(level.colorize('${_currentTimeStamp()} ${level.prefix} $message'));
}

class LogFileManager {
  LogFileManager._(this._sendPort);

  static LogFileManager? _instance;

  static LogFileManager? get instance => _instance ??= _fromOtherIsolate();

  static const _logPortName = 'one.mixin.logger.send_port';

  static LogFileManager? _fromOtherIsolate() {
    final sendPort = IsolateNameServer.lookupPortByName(_logPortName);
    if (sendPort == null) {
      return null;
    }
    return LogFileManager._(sendPort);
  }

  static Future<void> init(String logDir) async {
    final receiver = ReceivePort();
    await Isolate.spawn(
      _logIsolate,
      [receiver.sendPort, logDir],
    );
    final sendPort = await receiver.first as SendPort;
    IsolateNameServer.registerPortWithName(sendPort, _logPortName);
  }

  final SendPort _sendPort;

  static Future<void> _logIsolate(List<dynamic> args) async {
    final responsePort = args[0] as SendPort;
    final messageReceiver = ReceivePort();
    final dir = args[1] as String;
    final logFileHandler = LogFileHandler(dir);
    messageReceiver.listen((message) {
      if (message is String) {
        logFileHandler.write(message);
      }
    });
    responsePort.send(messageReceiver.sendPort);
  }

  Future<void> write(String message) async {
    _sendPort.send(message);
  }
}

final _fileNameRegex = RegExp(r'^log_\d+.log$');
final _fileNumberExtractRegex = RegExp(r'(?<=_)\d+(?=.log)');

String _generateFileName(int number) => 'log_$number.log';

class LogFileHandler {
  LogFileHandler(
    this.directory, {
    this.maxFileCount = 10,
    this.maxFileLength = 1024 * 1024 * 10, // 10 MB
  })  : assert(maxFileCount >= 1),
        assert(maxFileLength >= 0) {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    } else if (!FileSystemEntity.isDirectorySync(directory)) {
      debugPrint('$directory is not a directory');
      return;
    }
    final files = dir
        .listSync(followLinks: false)
        .where((f) => f is File && _fileNameRegex.hasMatch(p.basename(f.path)))
        .map((e) {
          final number =
              _fileNumberExtractRegex.stringMatch(p.basename(e.path));
          assert(number != null, '${e.path} is not a log file');
          if (number == null) {
            return null;
          }
          final index = int.tryParse(number);
          assert(index != null, '${e.path} is not a log file');
          if (index == null) {
            return null;
          }
          return MapEntry(index, e as File);
        })
        .whereNotNull()
        .toList();
    this.files.addEntries(files);
    _prepareOutputFile();
  }

  void _prepareOutputFile() {
    final File outputFile;
    if (files.isEmpty) {
      final file = File(p.join(directory, _generateFileName(0)));
      files[0] = file;
      outputFile = file;
    } else {
      final max = files.keys.reduce(math.max);
      final file = files[max];
      assert(file != null, '$max is not a valid file index');
      if (file != null && file.lengthSync() < maxFileLength) {
        outputFile = file;
      } else {
        final nextIndex = max + 1;
        final file = File(p.join(directory, _generateFileName(nextIndex)));
        files[nextIndex] = file;
        outputFile = file;
      }
      if (files.length > maxFileCount) {
        final min = files.keys.reduce(math.min);
        final file = files[min];
        assert(file != null, '$min is not a valid file index');
        if (file != null) {
          file.deleteSync();
          files.remove(min);
        }
      }
    }
    try {
      outputFile.createSync();
    } catch (e) {
      debugPrint('Failed to create log file: $e');
      return;
    }
    _logFile = outputFile;
    _currentFileLength = outputFile.lengthSync();
  }

  final String directory;

  File? _logFile;
  int _currentFileLength = 0;

  final Map<int, File> files = {};

  final int maxFileCount;

  final int maxFileLength;

  void write(String message) {
    assert(_logFile != null, 'Log file is null');
    final bytes = utf8.encode('$message\n');
    _logFile!.writeAsBytesSync(bytes, mode: FileMode.append, flush: true);
    _currentFileLength += bytes.length;
    if (_currentFileLength > maxFileLength) {
      _prepareOutputFile();
    }
  }
}
