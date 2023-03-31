import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_app/utils/device_transfer/crc.dart';
import 'package:flutter_app/utils/device_transfer/json_transfer_data.dart';
import 'package:flutter_app/utils/device_transfer/transfer_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('transfer writer', () async {
    final sink = _BytesStreamSink();

    Future<void> writeJson(Map<String, dynamic> json) => writePacketToSink(
        sink,
        TransferJsonPacket(JsonTransferData(
          type: JsonTransferDataType.command,
          data: json,
        )));
    await writeJson({'abc': 1});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});

    final bytes = Uint8List.fromList(sink.data);
    final stream = Stream.value(Uint8List.fromList(bytes))
        .transform(const TransferProtocolTransform());
    final data = await stream.toList();
    expect(data.length, 5);

    final packet = data.first as TransferJsonPacket;
    final body = packet.json.data;
    expect(body, equals({'abc': 1}));
    d('utf8.decode(body): $body');
  });

  test('write file', () async {
    final sink = _BytesStreamSink();
    final messageId = const Uuid().v4();
    await writePacketToSink(
      sink,
      TransferAttachmentPacket(messageId: messageId, path: './LICENSE'),
    );
    final bytes = Uint8List.fromList(sink.data);
    final stream = Stream.value(Uint8List.fromList(bytes))
        .transform(const TransferProtocolTransform());
    final data = await stream.toList();
    expect(data.length, 1);
    final packet = data.first as TransferAttachmentPacket;
    expect(packet.messageId, messageId);
    d('packet.path: ${packet.path}');
  });

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
