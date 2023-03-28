import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../logger.dart';
import 'crc.dart';

const kTypeJson = 1;
const kTypeFile = 2;

/// -----------------------------------------------------------------
/// | type (1 byte) | body_length（4 bytes） | body | crc（8 bytes） |
/// ----------------------------------------------------------------
abstract class TransferProtocol {
  int get type;

  Future<int> get bodyLength;

  Future<Uint8List> get body;
}

abstract class TransferProtocolWriter extends TransferProtocol {
  TransferProtocolWriter();

  factory TransferProtocolWriter.json(Map<String, dynamic> json) =>
      _ByteTransferProtocol(
        Uint8List.fromList(utf8.encode(jsonEncode(json))),
        kTypeJson,
      );

  /// return: body check sum
  @protected
  Future<int> writeBody(EventSink<List<int>> sink);

  Future<void> write(EventSink<List<int>> sink) async {
    final header = ByteData(5)..setInt8(0, type);
    final bodyLength = await this.bodyLength;
    header.setInt32(1, bodyLength);
    sink.add(header.buffer.asUint8List());

    final checkSum = await writeBody(sink);

    final checkSumByte = Uint8List(8);
    checkSumByte.buffer.asByteData().setUint64(0, checkSum);
    sink.add(checkSumByte);
  }
}

class TransferProtocolTransform
    extends StreamTransformerBase<Uint8List, TransferProtocol> {
  const TransferProtocolTransform();

  @override
  Stream<TransferProtocol> bind(Stream<Uint8List> stream) =>
      Stream<TransferProtocol>.eventTransformed(
        stream,
        _TransferProtocolSink.new,
      );
}

class _TransferProtocolSink extends EventSink<Uint8List> {
  _TransferProtocolSink(this._sink);

  final EventSink<TransferProtocol> _sink;

  /// The carry-over from the previous chunk.
  Uint8List? _carry;

  @override
  void add(Uint8List event) {
    final Uint8List data;
    final carry = _carry;
    if (carry != null) {
      data = Uint8List.fromList(carry + event);
      _carry = null;
    } else {
      data = event;
    }

    if (data.length < 5) {
      _carry = data;
      return;
    }

    final bytes = data.buffer.asByteData();
    final type = bytes.getInt8(0);
    final bodyLength = bytes.getInt32(1);
    const bodyStart = 5;
    final bodyEnd = bodyStart + bodyLength; // exclusive
    if (bodyLength < 0) {
      _sink.addError('body length error. $bodyLength');
      return;
    }

    final packetEnd = bodyEnd + 8 /* crc */;

    if (data.length < packetEnd) {
      d('no enough data. ${data.length} < $packetEnd');
      _carry = data;
      return;
    }

    final body = data.sublist(bodyStart, bodyEnd);
    // check sum
    final checkSum = bytes.getUint64(bodyEnd);
    final checkSum2 = calculateCrc32(body);
    if (checkSum != checkSum2) {
      _sink.addError('check sum error. $checkSum != $checkSum2');
      return;
    }

    _sink.add(_ByteTransferProtocol(body, type));
    if (data.length > packetEnd) {
      add(data.sublist(packetEnd));
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    _sink.close();
  }
}

class _ByteTransferProtocol extends TransferProtocolWriter {
  _ByteTransferProtocol(this._body, this.type);

  final Uint8List _body;

  @override
  Future<Uint8List> get body => Future.value(_body);

  @override
  final int type;

  @override
  Future<int> get bodyLength => Future.value(_body.length);

  @override
  Future<int> writeBody(EventSink<List<int>> sink) async {
    sink.add(_body);
    return calculateCrc32(_body);
  }
}
