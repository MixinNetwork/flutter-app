import 'package:ansicolor/ansicolor.dart';
import 'package:flutter/foundation.dart';

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

String colorize(String message) {
  final ansiColorMessage =
      message.startsWith(ansiEscape) && message.endsWith(ansiDefault);

  if (!ansiColorMessage) return _debugPen(message);

  return message;
}

void v(String message) {
  debugPrint(_verbosePen('$_verbosePrefix $message'));
}

void d(String message) {
  debugPrint(_debugPen('$_debugPrefix $message'));
}

void i(String message) {
  debugPrint(_infoPen('$_infoPrefix $message'));
}

void w(String message) {
  debugPrint(_warningPen('$_warningPrefix $message'));
}

void e(String message) {
  debugPrint(_errorPen('$_errorPrefix $message'));
}

void wtf(String message) {
  debugPrint(_wtfPen('$_wtfPrefix $message'));
}
