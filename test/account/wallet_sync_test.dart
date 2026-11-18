import 'package:decimal/decimal.dart';
import 'package:flutter_app/account/wallet_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

SafeUtxoOutput _output(String asset, String amount, {String? inscription}) =>
    SafeUtxoOutput(
      outputId: '',
      transactionHash: '',
      outputIndex: 0,
      asset: asset,
      sequence: 0,
      amount: amount,
      mask: '',
      keys: const [],
      receivers: const [],
      receiversHash: '',
      receiversThreshold: 1,
      extra: '',
      state: 'unspent',
      createdAt: '',
      updatedAt: '',
      signedBy: '',
      signedAt: '',
      spentAt: '',
      inscriptionHash: inscription,
    );

void main() {
  test('sums the outputs of each asset without rounding', () {
    final balances = <String, Decimal>{};
    sumOutputs(balances, [_output('a', '0.1'), _output('b', '5')]);
    sumOutputs(balances, [_output('a', '0.2')]);
    expect(balances.map((k, v) => MapEntry(k, v.toString())), {
      'a': '0.3',
      'b': '5',
    });
  });

  test('skips outputs that hold an inscription', () {
    final balances = <String, Decimal>{};
    sumOutputs(balances, [
      _output('a', '1'),
      _output('a', '0.00000001', inscription: 'hash'),
      _output('a', '2', inscription: ''),
    ]);
    expect(balances['a'].toString(), '3');
  });
}
