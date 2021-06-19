import 'package:ansicolor/ansicolor.dart';
import 'package:flutter/foundation.dart';

// ignore_for_file: avoid_print

const kLogMode = !kReleaseMode;

const _verbosePrefix = '[V]';
const _debugPrefix = '[D]';
const _infoPrefix = '[I]';
const _warningPrefix = '[W]';
const _errorPrefix = '[E]';
const _wtfPrefix = '[WTF]';

final _verbosePen = AnsiPen()..gray();
final _debugPen = AnsiPen()..blue();
final _infoPen = AnsiPen()..green();
final _warningPen = AnsiPen()..yellow();
final _errorPen = AnsiPen()..red();
final _wtfPen = AnsiPen()..magenta();

String colorizeNonAnsi(String message) {
  final ansiColorMessage =
      message.startsWith(ansiEscape) && message.endsWith(ansiDefault);

  if (!ansiColorMessage) return _debugPen(message);

  return message;
}

void v(String message) {
  if (!kLogMode) return;
  print(_verbosePen('$_verbosePrefix $message'));
}

void d(String message) {
  if (!kLogMode) return;
  print(_debugPen('$_debugPrefix $message'));
}

void i(String message) {
  if (!kLogMode) return;
  print(_infoPen('$_infoPrefix $message'));
}

void w(String message) {
  if (!kLogMode) return;
  print(_warningPen('$_warningPrefix $message'));
}

void e(String message) {
  if (!kLogMode) return;
  print(_errorPen('$_errorPrefix $message'));
}

void wtf(String message) {
  print(_wtfPen('$_wtfPrefix $message'));
}
