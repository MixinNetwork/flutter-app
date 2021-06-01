import 'package:ansicolor/ansicolor.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test logger colors', () {
    ansiColorDisabled = false;
    // ignore: avoid_print
    print(colorize('[V] ..... verbose message ......'));
    // ignore: avoid_print
    print(colorize('[D] ===== debug message ====='));
    // ignore: avoid_print
    print(colorize('[I] info message'));
    // ignore: avoid_print
    print(colorize('[W] Just a warning! ${StackTrace.current}'));
    // ignore: avoid_print
    print(colorize('[E] Error! Something bad happened ${StackTrace.current}'));
  });
}
