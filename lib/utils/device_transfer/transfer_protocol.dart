import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import '../logger.dart';
import 'crc.dart';
import 'json_transfer_data.dart';
import 'transfer_data_command.dart';

const kTypeCommand = 1;
const kTypeJson = 2;
const kTypeFile = 3;

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

abstract class _TransferJsonPacket extends TransferPacket {
  _TransferJsonPacket(Map<String, dynamic> json)
      : _data = Uint8List.fromList(utf8.encode(jsonEncode(json)));

  _TransferJsonPacket._fromData(this._data);

  final Uint8List _data;

  @override
  int get _type => kTypeJson;

  @override
  Future<int> get _bodyLength => Future.value(_data.length);

  @override
  Future<int> _writeBodyToSink(EventSink<List<int>> sink) async {
    sink.add(_data);
    return calculateCrc32(_data);
  }
}

class TransferDataPacket extends _TransferJsonPacket {
  TransferDataPacket(this.data) : super(data.toJson());

  TransferDataPacket._fromData(super.data)
      : data = JsonTransferData.fromJson(
            jsonDecode(utf8.decode(data)) as Map<String, dynamic>),
        super._fromData();

  final JsonTransferData data;

  @override
  int get _type => kTypeJson;
}

class TransferCommandPacket extends _TransferJsonPacket {
  TransferCommandPacket(this.command) : super(command.toJson());

  TransferCommandPacket._fromData(super.data)
      : command = TransferDataCommand.fromJson(
            jsonDecode(utf8.decode(data)) as Map<String, dynamic>),
        super._fromData();

  final TransferDataCommand command;

  @override
  int get _type => kTypeCommand;
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

var _lock = Lock(reentrant: true);

Future<void> writePacketToSink(
  EventSink<List<int>> sink,
  TransferPacket packet,
) =>
    _lock.synchronized(() async {
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
    });

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
  _TransferJsonPacketBuilder(super.expectedBodyLength, this.creator);

  final _body = <int>[];
  final _TransferJsonPacket Function(Uint8List jsonBytes) creator;

  @override
  bool doWriteBody(Uint8List bytes) {
    _body.addAll(bytes);
    return true;
  }

  @override
  _TransferJsonPacket build() {
    assert(_writeBodyLength == expectedBodyLength);
    final json = Uint8List.fromList(_body);
    try {
      return creator(json);
    } catch (error, stacktrace) {
      e('_TransferJsonPacketBuilder#build: $error, $stacktrace \ncontent: ${utf8.decode(json, allowMalformed: true)}');
      rethrow;
    }
  }
}

class _TransferAttachmentPacketBuilder extends _TransferPacketBuilder {
  _TransferAttachmentPacketBuilder(super.expectedBodyLength, this.folder);

  final String folder;

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
      final tempFileName = const Uuid().v4();
      final file = File(p.join(folder, tempFileName));
      d('write $messageId attachment to: ${file.path}');
      _file = file;
      if (file.existsSync()) {
        file.deleteSync();
      }
      file
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes.sublist(_kUUIDBytesCount), flush: true);
    } else {
      _file!.writeAsBytesSync(bytes, mode: FileMode.append, flush: true);
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
    assert(
      _file!.lengthSync() == _writeBodyLength - _kUUIDBytesCount,
      'file length != writeBodyLength',
    );
    d('write $_messageId attachment done, bytes: ${_writeBodyLength - _kUUIDBytesCount}');
    return TransferAttachmentPacket(
      messageId: _messageId!,
      path: _file!.path,
    );
  }
}

class TransferProtocolTransform
    extends StreamTransformerBase<Uint8List, TransferPacket> {
  const TransferProtocolTransform({
    required this.fileFolder,
  });

  /// the file folder to save attachment.
  final String fileFolder;

  @override
  Stream<TransferPacket> bind(Stream<Uint8List> stream) =>
      Stream<TransferPacket>.eventTransformed(
        stream,
        (sink) => _TransferProtocolSink(sink, fileFolder),
      );
}

class _TransferProtocolSink extends EventSink<Uint8List> {
  _TransferProtocolSink(this._sink, this.folder);

  final EventSink<TransferPacket> _sink;
  final String folder;

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
          case kTypeCommand:
            _builder = _TransferJsonPacketBuilder(
              bodyLength,
              TransferCommandPacket._fromData,
            );
            break;
          case kTypeJson:
            _builder = _TransferJsonPacketBuilder(
              bodyLength,
              TransferDataPacket._fromData,
            );
            break;
          case kTypeFile:
            _builder = _TransferAttachmentPacketBuilder(bodyLength, folder);
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
            _sink.addError(
              'crc not match. expected $crc, actually ${builder.bodyCrc}',
              StackTrace.current,
            );
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
