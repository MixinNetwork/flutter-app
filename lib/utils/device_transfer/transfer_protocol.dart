import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../file.dart';
import '../logger.dart';
import 'crc.dart';
import 'transfer_data_json_wrapper.dart';

const kTypeJson = 1;
const kTypeFile = 2;

/// -----------------------------------------------------------------
/// | type (1 byte) | body_length（4 bytes） | body | crc（8 bytes） |
/// ----------------------------------------------------------------
abstract class TransferPacket {
  int get _type;

  Future<int> get _bodyLength;

  /// return: body check sum
  @protected
  Future<int> _writeBodyToSink(EventSink<List<int>> sink);
}

class TransferJsonPacket extends TransferPacket {
  TransferJsonPacket(this.json)
      : _data = Uint8List.fromList(utf8.encode(jsonEncode(json.toJson())));

  TransferJsonPacket._fromData(this._data)
      : json = TransferDataJsonWrapper.fromJson(
            jsonDecode(utf8.decode(_data)) as Map<String, dynamic>);

  final Uint8List _data;

  @override
  int get _type => kTypeJson;

  final TransferDataJsonWrapper json;

  @override
  Future<int> get _bodyLength => Future.value(_data.length);

  @override
  Future<int> _writeBodyToSink(EventSink<List<int>> sink) async {
    sink.add(_data);
    return calculateCrc32(_data);
  }
}

const _kUUIDBytesCount = 16;

class TransferAttachmentPacket extends TransferPacket {
  TransferAttachmentPacket({
    required this.messageId,
    required this.path,
  });

  final String messageId;
  final String path;

  @override
  int get _type => kTypeFile;

  @override
  Future<int> get _bodyLength async {
    final file = File(path);
    if (!file.existsSync()) {
      e('_AttachmentTransferProtocol#bodyLength: file not exist. $path');
      return 0;
    }
    final fileLength = await file.length();
    return _kUUIDBytesCount + fileLength;
  }

  @override
  Future<int> _writeBodyToSink(EventSink<List<int>> sink) async {
    final crc = CrcCalculator();

    // first 16 bytes, messageId (uuid)
    final messageIdBytes = Uuid.parseAsByteList(messageId);
    if (messageIdBytes.length != _kUUIDBytesCount) {
      e('_AttachmentTransferProtocol#writeBody: messageIdBytes.length != 16');
      return 0;
    }
    crc.addBytes(messageIdBytes);
    sink.add(messageIdBytes);

    final file = File(path);
    if (!file.existsSync()) {
      e('_AttachmentTransferProtocol#writeBody: file not exist. $path');
      return 0;
    }
    final fileStream = file.openRead();
    await for (final bytes in fileStream) {
      sink.add(bytes);
      crc.addBytes(Uint8List.fromList(bytes));
    }

    return crc.result;
  }
}

Future<void> writePacketToSink(
  EventSink<List<int>> sink,
  TransferPacket packet,
) async {
  final bodyLength = await packet._bodyLength;

  if (bodyLength == 0) {
    w('bodyLength is 0, skip write');
    return;
  }

  final header = ByteData(5)
    ..setInt8(0, packet._type)
    ..setInt32(1, bodyLength);
  sink.add(header.buffer.asUint8List());

  final checkSum = await packet._writeBodyToSink(sink);

  final checkSumByte = Uint8List(8);
  checkSumByte.buffer.asByteData().setUint64(0, checkSum);
  sink.add(checkSumByte);
}

abstract class _TransferPacketBuilder {
  _TransferPacketBuilder(this.expectedBodyLength);

  final int expectedBodyLength;

  var _writeBodyLength = 0;

  final _crc = CrcCalculator();

  int get bodyCrc => _crc.result;

  /// return: true if write success, false if write failed.
  bool doWriteBody(Uint8List bytes);

  @nonVirtual
  bool writeBody(Uint8List bytes) {
    final write = doWriteBody(bytes);
    if (!write) {
      i('writeBody, bytes.length: ${bytes.length}');
      return false;
    }
    _writeBodyLength += bytes.length;
    _crc.addBytes(bytes);
    assert(_writeBodyLength <= expectedBodyLength);
    return true;
  }

  TransferPacket build();
}

class _TransferJsonPacketBuilder extends _TransferPacketBuilder {
  _TransferJsonPacketBuilder(super.expectedBodyLength);

  final _body = <int>[];

  @override
  bool doWriteBody(Uint8List bytes) {
    _body.addAll(bytes);
    return true;
  }

  @override
  TransferJsonPacket build() {
    assert(_writeBodyLength == expectedBodyLength);
    return TransferJsonPacket._fromData(Uint8List.fromList(_body));
  }
}

class _TransferAttachmentPacketBuilder extends _TransferPacketBuilder {
  _TransferAttachmentPacketBuilder(super.expectedBodyLength);

  File? _file;
  String? _messageId;

  @override
  bool doWriteBody(Uint8List bytes) {
    if (_file == null) {
      if (bytes.length < _kUUIDBytesCount) {
        e('_TransferAttachmentPacketBuilder#doWriteBody: bytes.length < 16');
        return false;
      }
      final messageIdBytes = bytes.sublist(0, _kUUIDBytesCount);
      final messageId = Uuid.unparse(messageIdBytes);
      _messageId = messageId;
      final path = '${mixinDocumentsDirectory.path}/tmp/$messageId';
      final file = File(path);
      _file = file;
      if (file.existsSync()) {
        file.delete();
      }
      file
        ..createSync(recursive: true)
        ..writeAsBytes(bytes.sublist(_kUUIDBytesCount), flush: true);
    } else {
      _file!.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    }
    return true;
  }

  @override
  TransferAttachmentPacket build() {
    assert(_writeBodyLength == expectedBodyLength,
        'writeBodyLength != expectedBodyLength');
    if (_file == null || _messageId == null) {
      e('_TransferAttachmentPacketBuilder#build: file or messageId is null');
      throw Exception('file or messageId is null');
    }
    return TransferAttachmentPacket(
      messageId: _messageId!,
      path: _file!.path,
    );
  }
}

class TransferProtocolTransform
    extends StreamTransformerBase<Uint8List, TransferPacket> {
  const TransferProtocolTransform();

  @override
  Stream<TransferPacket> bind(Stream<Uint8List> stream) =>
      Stream<TransferPacket>.eventTransformed(
        stream,
        _TransferProtocolSink.new,
      );
}

class _TransferProtocolSink extends EventSink<Uint8List> {
  _TransferProtocolSink(this._sink);

  final EventSink<TransferPacket> _sink;

  /// The carry-over from the previous chunk.
  Uint8List? _carry;

  _TransferPacketBuilder? _builder;

  @override
  void add(Uint8List event) {
    Uint8List data;
    final carry = _carry;
    if (carry != null) {
      data = Uint8List.fromList(carry + event);
      _carry = null;
    } else {
      data = event;
    }

    while (true) {
      if (_builder == null) {
        if (data.length < 5) {
          _carry = data;
          return;
        }
        final bytes = data.buffer.asByteData();
        final type = bytes.getInt8(0);
        final bodyLength = bytes.getInt32(1);
        switch (type) {
          case kTypeJson:
            _builder = _TransferJsonPacketBuilder(bodyLength);
            break;
          case kTypeFile:
            _builder = _TransferAttachmentPacketBuilder(bodyLength);
            break;
          default:
            _sink.addError('unknown type: $type', StackTrace.current);
            return;
        }
        data = data.sublist(5);
      } else {
        final builder = _builder!;
        final need = builder.expectedBodyLength - builder._writeBodyLength;
        if (data.length < need) {
          final write = builder.writeBody(data);
          if (!write) {
            _carry = data;
          }
          return;
        } else {
          final write = builder.writeBody(data.sublist(0, need));
          assert(write,
              'data length larger than expected, this should not be happen.');

          final left = data.sublist(need);
          // check if left is enough for crc
          if (left.length < 8) {
            _carry = left;
            return;
          }
          // check crc
          final crc = left.buffer.asByteData().getUint64(0);
          if (crc != builder.bodyCrc) {
            _sink.addError('crc not match', StackTrace.current);
            return;
          }
          final packet = builder.build();
          _sink.add(packet);
          _builder = null;
          data = left.sublist(8);
        }
      }
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