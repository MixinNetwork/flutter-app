import 'package:flutter_app/utils/device_transfer/transfer_data_command.dart';
import 'package:flutter_app/utils/proxy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('proxy and transfer diagnostics omit credentials', () {
    final proxy = ProxyConfig(
      type: ProxyType.http,
      host: 'localhost',
      port: 8080,
      id: 'proxy',
      username: 'secret-user',
      password: 'secret-password',
    );
    expect(proxy.toUri(), contains('secret-password'));
    expect(proxy.toString(), isNot(contains('secret-user')));
    expect(proxy.toString(), isNot(contains('secret-password')));
    final command = TransferDataCommand.push(
      ip: '127.0.0.1',
      port: 1234,
      deviceId: 'device',
      code: 9876,
      secretKey: 'secret-key',
    );
    expect(command.toJson()['secret_key'], 'secret-key');
    expect(command.toString(), isNot(contains('secret-key')));
    expect(command.toString(), isNot(contains('9876')));
  });
}
