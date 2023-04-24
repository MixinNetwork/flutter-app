import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/utils/device_transfer/json_transfer_data.dart';
import 'package:flutter_app/utils/device_transfer/transfer_data_command.dart';
import 'package:flutter_app/utils/device_transfer/transfer_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('transfer writer', () async {
    final sink = _BytesStreamSink();

    Future<void> writeJson(Map<String, dynamic> json) => writePacketToSink(
        sink,
        TransferDataPacket(JsonTransferData(
          type: JsonTransferDataType.message,
          data: json,
        )));
    await writeJson({'abc': 1});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});

    final bytes = Uint8List.fromList(sink.data);
    final stream = Stream.value(Uint8List.fromList(bytes))
        .transform(const TransferProtocolTransform(fileFolder: ''));
    final data = await stream.toList();
    expect(data.length, 5);

    final packet = data.first as TransferDataPacket;
    final body = packet.data.data;
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
    final stream = Stream.value(Uint8List.fromList(bytes)).transform(
        TransferProtocolTransform(fileFolder: Directory.systemTemp.path));
    final data = await stream.toList();
    expect(data.length, 1);
    final packet = data.first as TransferAttachmentPacket;
    expect(packet.messageId, messageId);
    d('packet.path: ${packet.path}');
  });

  test('write command and data', () async {
    final sink = _BytesStreamSink();
    const deviceId = '82525DEB-C242-57A2-9A14-8C473C2B1300';
    await sink.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 1 / 3,
      ),
    );
    await sink.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 0,
      ),
    );
    await sink.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 0,
      ),
    );
    await sink.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 1,
      ),
    );
    await sink.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 1,
      ),
    );

    final bytes = Uint8List.fromList(sink.data);
    final stream = Stream.value(Uint8List.fromList(bytes))
        .transform(const TransferProtocolTransform(fileFolder: ''));
    final data = await stream.toList();
    expect(data.length, 5);
    for (final command in data) {
      expect(command, isA<TransferCommandPacket>());
    }
    final packet = data.first as TransferCommandPacket;
    d('utf8.decode(body): ${packet.command}');
  });
}

class _BytesStreamSink implements IOSink {
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
  Future addStream(Stream<List<int>> stream) {
    throw UnimplementedError();
  }

  @override
  Future get done => throw UnimplementedError();

  @override
  Future flush() async {}

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}
  @override
  Encoding encoding = utf8;

  @override
  Future close() async {}
}
