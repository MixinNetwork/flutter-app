import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/utils/device_transfer/cipher.dart';
import 'package:flutter_app/utils/device_transfer/json_transfer_data.dart';
import 'package:flutter_app/utils/device_transfer/socket_wrapper.dart';
import 'package:flutter_app/utils/device_transfer/transfer_data_command.dart';
import 'package:flutter_app/utils/device_transfer/transfer_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('transfer writer', () async {
    final secretKey = generateTransferKey();
    final socket = MockTransferSocket(secretKey);
    Future<void> writeJson(Map<String, dynamic> json) => writePacketToSink(
          socket,
          TransferDataPacket(JsonTransferData(
            type: JsonTransferDataType.message,
            data: json,
          )),
          hMacKey: secretKey.hMacKey,
          aesKey: secretKey.aesKey,
        );
    await writeJson({'abc': 1});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});

    final bytes = Uint8List.fromList(socket.sink.data);

    final stream = Stream<TransferPacket>.eventTransformed(
      Stream.value(Uint8List.fromList(bytes)),
      (sink) => TransferProtocolSink(sink, '', secretKey),
    );
    final data = await stream.toList();
    expect(data.length, 5);

    final packet = data.first as TransferDataPacket;
    final body = packet.data.data;
    expect(body, equals({'abc': 1}));
    d('utf8.decode(body): $body');
  });

  test('write file', () async {
    final secretKey = generateTransferKey();
    final socket = MockTransferSocket(secretKey);
    final messageId = const Uuid().v4();

    await writePacketToSink(
      socket,
      TransferAttachmentPacket(messageId: messageId, path: './LICENSE'),
      hMacKey: secretKey.hMacKey,
      aesKey: secretKey.aesKey,
    );

    final bytes = Uint8List.fromList(socket.sink.data);

    final stream = Stream<TransferPacket>.eventTransformed(
      Stream.value(Uint8List.fromList(bytes)),
      (sink) =>
          TransferProtocolSink(sink, Directory.systemTemp.path, secretKey),
    );

    final data = await stream.toList();
    expect(data.length, 1);
    final packet = data.first as TransferAttachmentPacket;
    expect(packet.messageId, messageId);
    d('packet.path: ${packet.path}');
  });

  test('write command and data', () async {
    final secretKey = generateTransferKey();

    final socket = MockTransferSocket(secretKey);
    const deviceId = '82525DEB-C242-57A2-9A14-8C473C2B1300';
    await socket.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 1 / 3,
      ),
    );
    await socket.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 0,
      ),
    );
    await socket.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 0,
      ),
    );
    await socket.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 1,
      ),
    );
    await socket.addCommand(
      TransferDataCommand.progress(
        deviceId: deviceId,
        progress: 1,
      ),
    );

    final bytes = Uint8List.fromList(socket.sink.data);
    final stream = Stream<TransferPacket>.eventTransformed(
      Stream.value(Uint8List.fromList(bytes)),
      (sink) => TransferProtocolSink(sink, '', secretKey),
    );
    final data = await stream.toList();
    expect(data.length, 5);
    for (final command in data) {
      expect(command, isA<TransferCommandPacket>());
    }
    final packet = data.first as TransferCommandPacket;
    d('utf8.decode(body): ${packet.command}');
  });

  test('benchmark json', () async {
    final secretKey = generateTransferKey();

    final socket = MockTransferSocket(secretKey);

    Future<void> writeJson(Map<String, dynamic> json) => writePacketToSink(
          socket,
          TransferDataPacket(JsonTransferData(
            type: JsonTransferDataType.message,
            data: json,
          )),
          hMacKey: secretKey.hMacKey,
          aesKey: secretKey.aesKey,
        );

    const length = 1000 * 100;
    for (var i = 0; i < length; i++) {
      await writeJson({'test': i});
    }

    final bytes = Uint8List.fromList(socket.sink.data);

    i('size: ${bytes.length / 1024 / 1024} MB');

    final stopwatch = Stopwatch()..start();
    final stream = Stream<TransferPacket>.eventTransformed(
      Stream.value(Uint8List.fromList(bytes)),
      (sink) => TransferProtocolSink(sink, '', secretKey),
    );
    final data = await stream.toList();
    expect(data.length, length);
    i('cost: ${stopwatch.elapsedMilliseconds}ms');
  });

  test('benchmark file', () async {
    final secretKey = generateTransferKey();

    final socket = MockTransferSocket(secretKey);

    for (var i = 0; i < 10000; i++) {
      final messageId = const Uuid().v4();
      await writePacketToSink(
        socket,
        TransferAttachmentPacket(messageId: messageId, path: './LICENSE'),
        aesKey: secretKey.aesKey,
        hMacKey: secretKey.hMacKey,
      );
    }

    final bytes = Uint8List.fromList(socket.sink.data);

    i('size: ${bytes.length / 1024 / 1024} MB');

    final stopwatch = Stopwatch()..start();
    final stream = Stream<TransferPacket>.eventTransformed(
      Stream.value(Uint8List.fromList(bytes)),
      (sink) => TransferProtocolSink(
        sink,
        Directory.systemTemp.path,
        secretKey,
      ),
    );
    final data = await stream.toList();
    expect(data.length, 10000);
    i('cost: ${stopwatch.elapsedMilliseconds}ms');
  }, timeout: const Timeout(Duration(minutes: 2)));
}

class MockTransferSocket extends TransferSocket {
  MockTransferSocket(super.secretKey) : super.create();

  final sink = _BytesStreamSink();

  @override
  void add(List<int> data) => sink.add(data);

  @override
  Future<void> close() => sink.close();

  @override
  void destroy() {}

  @override
  Future<void> flush() => sink.flush();
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
