import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_app/utils/device_transfer/crc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crc test', () {
    expect(
        calculateCrc32(Uint8List.fromList(utf8.encode('abcdefg'))), 824863398);
    expect(calculateCrc32(Uint8List.fromList(utf8.encode('yHm7QnW2Rp'))),
        3806008316);
    final calculator = CrcCalculator()
      ..addBytes(Uint8List.fromList(utf8.encode('yHm7Qn')))
      ..addBytes(Uint8List.fromList(utf8.encode('W2Rp')));
    expect(calculator.result, 3806008316);

    expect(calculateCrc32(Uint8List.fromList(utf8.encode('4fEwLdG8tK'))),
        2006416362);
    expect(calculateCrc32(Uint8List.fromList(utf8.encode('J9uX6vZpNc'))),
        4072379794);
    expect(calculateCrc32(Uint8List.fromList(utf8.encode('5VhQxPbUaS'))),
        1074432487);
    expect(calculateCrc32(Uint8List.fromList(utf8.encode('A2kDlTjRgM'))),
        69700325);
  });

  test('test', () {
    final json = {
      'data': {
        'device_id': '82525DEB-C242-57A2-9A14-8C473C2B1300',
        'action': 'progress',
        'version': 1,
        'ip': null,
        'port': null,
        'secret_key': null,
        'platform': 'desktop',
        'code': null,
        'total': null,
        'user_id': null,
        'progress': 0.03749531308586427
      },
      'type': 'command'
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    expect(calculateCrc32(bytes), 4126395539);
  });
}
