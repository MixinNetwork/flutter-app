import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_app/utils/device_transfer/transfer_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_logger/mixin_logger.dart';

void main() {
  test('transfer writer', () async {
    const json = {'a': 1};
    final sink = _BytesStreamSink();
    await TransferProtocolWriter.json(json).write(sink);
    final bytes = Uint8List.fromList(sink.data);
    final length = bytes.buffer.asByteData().getInt32(1);
    expect(length, utf8.encode(jsonEncode(json)).length);

    final stream = Stream.value(Uint8List.fromList(bytes))
        .transform(TransferProtocolTransform());
    final data = await stream.toList();
    expect(data.length, 1);

    final protocol = data.first;
    expect(protocol.type, kTypeJson);
    final body = await protocol.body;
    expect(utf8.decode(body), jsonEncode(json));
    d('utf8.decode(body): ${utf8.decode(body)}');
  });
}

class _BytesStreamSink extends EventSink<List<int>> {
  final data = <int>[];

  Object? error;

  @override
  void add(List<int> event) {
    data.addAll(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    this.error = error;
    e('error: $error, stackTrace: $stackTrace');
  }

  @override
  void close() {}
}
