import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a session keeps the Signal device id that earlier versions stored', () {
    // The values that ulid 2.0.1 computed. Sessions and sender keys in the
    // Signal store use them, so a dependency upgrade must not change them.
    expect('00000000-0000-0000-0000-000000000000'.getDeviceId(), 220137401);
    expect('9b8609c5-74f0-4630-9512-211fd5470826'.getDeviceId(), 200901042);
    expect('f1e2d3c4-b5a6-4978-8a9b-0c1d2e3f4a5b'.getDeviceId(), 81539281);
  });

  test('a missing session uses the primary device id', () {
    expect((null as String?).getDeviceId(), 1);
    expect(''.getDeviceId(), 1);
  });
}
