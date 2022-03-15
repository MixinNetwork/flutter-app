import 'package:flutter_app/utils/auto_update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test version', () {
    expect(currentVersionIsLatest('v22.0.1', 'v22.0.1'), true);
    expect(currentVersionIsLatest('v0.22.0', 'v0.22.1'), false);
    expect(currentVersionIsLatest('v0.22.0', 'v0.22.2'), false);
    expect(currentVersionIsLatest('v0.22.0', 'v0.21.2'), true);
    expect(currentVersionIsLatest('v0.21.9', 'v0.21.10'), false);
    expect(currentVersionIsLatest('v1.22.9', 'v0.21.10'), true);
    expect(currentVersionIsLatest('v1.22.9', 'v1.21.10'), true);
    expect(currentVersionIsLatest('v1.22.9', 'v1.22.10'), false);
  });
}
