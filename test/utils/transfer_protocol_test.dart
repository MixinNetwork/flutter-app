import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_app/utils/device_transfer/cipher.dart';
import 'package:flutter_app/utils/device_transfer/json_transfer_data.dart';
import 'package:flutter_app/utils/device_transfer/socket_wrapper.dart';
import 'package:flutter_app/utils/device_transfer/transfer_data_command.dart';
import 'package:flutter_app/utils/device_transfer/transfer_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

String _generateLargeString(int length) {
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    final index = i % 26;
    const alphabet = 'abcdefghijklmnopqrstuvwxyz';
    buffer.write(alphabet[index]);
  }
  return buffer.toString();
}

Future<String> _fileMd5(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final digest = md5.convert(bytes);
  return hex.encode(digest.bytes);
}

Future<String> _createTempFile(int fileSize) async {
  final file = File(p.join(Directory.systemTemp.path, const Uuid().v4()))
    ..createSync()
    ..writeAsStringSync(_generateLargeString(fileSize));
  return file.path;
}

void main() {
  test('transfer writer', () async {
    final secretKey = generateTransferKey();
    final socket = MockTransferSocket(secretKey);
    Future<void> writeJson(Map<String, dynamic> json) => TransferDataPacket(
      JsonTransferData(type: JsonTransferDataType.message, data: json),
    ).write(socket, secretKey);

    await writeJson({'abc': 1});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    await writeJson({'bdfasf': 2124124});
    final largeStr = _generateLargeString(1024 * 500 - 100);
    await writeJson({'large': largeStr});

    final bytes = Uint8List.fromList(socket.sink.data);

    final stream = Stream<TransferPacket>.eventTransformed(
      Stream.value(Uint8List.fromList(bytes)),
      (sink) => TransferProtocolSink(sink, '', secretKey),
    );
    final data = await stream.toList();
    expect(data.length, 6);

    final packet = data.first as TransferDataPacket;
    final body = packet.data.data;
    expect(body, equals({'abc': 1}));
    d('utf8.decode(body): $body');
  });

  test('write file', () async {
    final secretKey = generateTransferKey();
    final socket = MockTransferSocket(secretKey);
    final messageId = const Uuid().v4();

    final emptyFile = await _createTempFile(0);
    i('emptyFile: ${File(emptyFile).lengthSync()}');
    await TransferAttachmentPacket(
      messageId: messageId,
      path: emptyFile,
    ).write(socket, secretKey);

    final testSmallFile = await _createTempFile(1024 * 1024 * 1 + 5);
    i('testSmallFile: ${File(testSmallFile).lengthSync()}');
    final smallFileMd5 = await _fileMd5(testSmallFile);

    await TransferAttachmentPacket(
      messageId: messageId,
      path: testSmallFile,
    ).write(socket, secretKey);

    final testLargeFile = await _createTempFile(1024 * 1024 * 50 + 6);
    i('testLargeFile: ${File(testLargeFile).lengthSync()}');
    final largeFileMd5 = await _fileMd5(testLargeFile);
    await TransferAttachmentPacket(
      messageId: messageId,
      path: testLargeFile,
    ).write(socket, secretKey);

    final bytes = Uint8List.fromList(socket.sink.data);

    i('bytes.length: ${bytes.length}');
    final stopwatch = Stopwatch()..start();
    final stream = Stream<TransferPacket>.eventTransformed(
      Stream.value(Uint8List.fromList(bytes)),
      (sink) =>
          TransferProtocolSink(sink, Directory.systemTemp.path, secretKey),
    );

    final data = await stream.toList();

    i(
      'parse ${bytes.length / (1024 * 1024)} MB, stopwatch.elapsed: ${stopwatch.elapsedMilliseconds}',
    );

    expect(data.length, 2);
    final packet = data.first as TransferAttachmentPacket;
    expect(packet.messageId, messageId);
    expect(await _fileMd5(packet.path), smallFileMd5);

    final packet2 = data[1] as TransferAttachmentPacket;
    expect(packet2.messageId, messageId);
    expect(await _fileMd5(packet2.path), largeFileMd5);

    d('packet.path: ${packet.path}');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('write command and data', () async {
    final secretKey = generateTransferKey();

    final socket = MockTransferSocket(secretKey);
    const deviceId = '82525DEB-C242-57A2-9A14-8C473C2B1300';
    await socket.addCommand(
      TransferDataCommand.progress(deviceId: deviceId, progress: 1 / 3),
    );
    await socket.addCommand(
      TransferDataCommand.progress(deviceId: deviceId, progress: 0),
    );
    await socket.addCommand(
      TransferDataCommand.progress(deviceId: deviceId, progress: 0),
    );
    await socket.addCommand(
      TransferDataCommand.progress(deviceId: deviceId, progress: 1),
    );
    await socket.addCommand(
      TransferDataCommand.progress(deviceId: deviceId, progress: 1),
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

    Future<void> writeJson(Map<String, dynamic> json) => TransferDataPacket(
      JsonTransferData(type: JsonTransferDataType.message, data: json),
    ).write(socket, secretKey);

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
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('benchmark file', () async {
    final secretKey = generateTransferKey();

    final socket = MockTransferSocket(secretKey);
    final random = Random.secure();
    final md5 = <String>[];

    for (var i = 0; i < 100; i++) {
      // Create 100 random temporary files from 500KB to 1MB
      final tempFile = await _createTempFile(
        500 * 1024 + random.nextInt(1024 * 500),
      );
      final messageId = const Uuid().v4();
      md5.add(await _fileMd5(tempFile));
      await TransferAttachmentPacket(
        messageId: messageId,
        path: tempFile,
      ).write(socket, secretKey);
    }

    final bytes = Uint8List.fromList(socket.sink.data);

    i('size: ${bytes.length / 1024 / 1024} MB');

    final stopwatch = Stopwatch()..start();
    final stream = Stream<TransferPacket>.eventTransformed(
      Stream.value(Uint8List.fromList(bytes)),
      (sink) =>
          TransferProtocolSink(sink, Directory.systemTemp.path, secretKey),
    );
    final data = await stream.toList();
    expect(data.length, 100);

    for (var i = 0; i < data.length; i++) {
      final packet = data[i];
      expect(packet, isA<TransferAttachmentPacket>());
      final attachment = packet as TransferAttachmentPacket;
      expect(await _fileMd5(attachment.path), md5[i]);
    }
    i('cost: ${stopwatch.elapsedMilliseconds}ms');
  }, timeout: const Timeout(Duration(minutes: 5)));
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
