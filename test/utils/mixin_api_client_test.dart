import 'dart:async';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter_app/utils/mixin_api_client.dart';
import 'package:flutter_app/utils/proxy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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

  test(
    'AbortableHttpClientAdapter sanitizes stream-phase abort errors for SendPort',
    () async {
      final unsendableHolder = ReceivePort();
      final testPort = ReceivePort();
      addTearDown(() {
        unsendableHolder.close();
        testPort.close();
      });

      final adapter = AbortableHttpClientAdapter(
        _StreamAbortClient(unsendableHolder),
      );
      final body = await adapter.fetch(
        RequestOptions(path: 'https://api.mixin.one/me'),
        null,
        null,
      );

      Object? caught;
      try {
        await body.stream.drain<void>();
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<http.RequestAbortedException>());
      expect(caught.runtimeType, http.RequestAbortedException);
      expect(() => testPort.sendPort.send(caught), returnsNormally);
    },
  );
}

class _UnsendableAbortException extends http.RequestAbortedException {
  _UnsendableAbortException(super.uri, this.holder);

  final ReceivePort holder;
}

class _StreamAbortClient extends http.BaseClient {
  _StreamAbortClient(this.holder);

  final ReceivePort holder;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream<List<int>>.error(
          _UnsendableAbortException(request.url, holder),
        ),
        200,
      );
}
