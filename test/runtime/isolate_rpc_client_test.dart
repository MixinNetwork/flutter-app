import 'dart:async';

import 'package:flutter_app/runtime/isolate/rpc_client.dart';
import 'package:flutter_app/runtime/isolate/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rpc client fails immediately when router send throws', () async {
    final router = IsolateRouter.main(
      inbound: const Stream<dynamic>.empty(),
      sendMessage: (_) => throw StateError('worker channel is null'),
    );
    addTearDown(router.dispose);

    final client = IsolateRpcClient(
      router,
      defaultTimeout: const Duration(milliseconds: 50),
    );
    addTearDown(client.dispose);

    await expectLater(
      client.request('upsertUser', payload: {'id': 'u1'}),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('worker channel is null'),
        ),
      ),
    );
  });
}
