import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('number format', () {
    expect(
      '-1681845116007986013692583.43574366'.numberFormat(),
      '-1,681,845,116,007,986,013,692,583.43574366',
    );
    expect('-0.43574366'.numberFormat(), '-0.43574366');
    expect('0.43574366'.numberFormat(), '0.43574366');
    expect('0.12345678910'.numberFormat(), '0.12345679');
    expect('-0.1234567891011'.numberFormat(), '-0.12345679');
    expect('0'.numberFormat(), '0');
    expect('0.0'.numberFormat(), '0');
    expect('1234567891011121314151617181920'.numberFormat(),
        '1,234,567,891,011,121,314,151,617,181,920');
    expect('1234567891011121314151617181920.0'.numberFormat(),
        '1,234,567,891,011,121,314,151,617,181,920');
  });
}
