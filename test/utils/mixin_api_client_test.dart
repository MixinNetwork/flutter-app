import 'package:dio/dio.dart';
import 'package:flutter_app/utils/mixin_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upgrade gate latches once and creates a local error', () {
    final gate = ApiUpgradeGate();
    final options = RequestOptions(path: '/me');

    expect(gate.isRequired, isFalse);
    expect(gate.require(), isTrue);
    expect(gate.require(), isFalse);
    expect(gate.isRequired, isTrue);
    expect(gate.error(options).error, isA<ApiUpgradeRequiredException>());
  });
}
