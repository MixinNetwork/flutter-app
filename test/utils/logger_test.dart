import 'package:ansicolor/ansicolor.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test logger colors', () {
    ansiColorDisabled = false;

    const originText = 'foo';
    final debugText = colorize(originText);

    expect(debugText, isNot(originText));
    expect(debugText, colorize(debugText));

    v('verbose message');
    d('debug message');
    i('info message');
    w('warning message');
    e('error message');
    wtf('wtf message');
  });
}
