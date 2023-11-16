import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../crypto/aes.dart';
import '../crypto/hmac.dart';
import '../logger.dart';
import 'cipher.dart';
import 'json_transfer_data.dart';
import 'socket_wrapper.dart';
import 'transfer_data_command.dart';

const kTypeCommand = 1;
const kTypeJson = 2;
const kTypeFile = 3;

///
/// ----------------------------------------------------------------
/// |                         TransferPacket                      |
/// ----------------------------------------------------------------
/// | type(1 byte) | body_length(4 bytes) | body | hMac(32 bytes)|
/// ----------------------------------------------------------------
///
///
/// ------------------------------------------------------------------------
/// |                             body                                     |
/// ------------------------------------------------------------------------
/// | uuid(16 bytes) for [kTypeFile] | iv(16 bytes) | data (aes encrypted) |
/// ------------------------------------------------------------------------
///
sealed class TransferPacket {
  TransferPacket();

  Future<void> write(TransferSocket sink, TransferSecretKey key);
}

const _kIVBytesCount = 16;

Future<void> _writeDataToSink({
  required TransferSocket sink,
  required TransferSecretKey key,
  required int type,
  required Uint8List data,
}) async {
  final iv = generateTransferIv();

  final encryptedData = AesCipher.encrypt(key: key.aesKey, iv: iv, data: data);

  final bodyLength = iv.length + encryptedData.length;

  final header = ByteData(5)
    ..setInt8(0, type)
    ..setInt32(1, bodyLength);

  final hMacCalculator = HMacCalculator(key.hMacKey)
    ..addBytes(iv)
    ..addBytes(encryptedData);
  sink
    ..add(header.buffer.asUint8List())
    ..add(iv)
    ..add(encryptedData)
    ..add(hMacCalculator.result);
  await sink.flush();
}

class TransferDataPacket extends TransferPacket {
  TransferDataPacket(this.data);

  final JsonTransferData data;

  @override
  Future<void> write(TransferSocket sink, TransferSecretKey key) async {
    final json = this.data.toJson();
    final data = Uint8List.fromList(utf8.encode(jsonEncode(json)));

    const kLargeDataThreshold = 500 * 1024; // 500KB
    if (data.length > kLargeDataThreshold) {
      w('packet size is too large: ${this.data.type} ${data.length} bytes');
      json.forEach((key, value) {
        final str = jsonEncode(value);
        w('packet data: $key ${str.length}');
      });
      return;
    }

    await _writeDataToSink(
      sink: sink,
      key: key,
      type: kTypeJson,
      data: data,
    );
  }
}

class TransferCommandPacket extends TransferPacket {
  TransferCommandPacket(this.command);

  final TransferDataCommand command;

  @override
  Future<void> write(TransferSocket sink, TransferSecretKey key) {
    final json = command.toJson();
    final data = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    return _writeDataToSink(
      sink: sink,
      key: key,
      type: kTypeCommand,
      data: data,
    );
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
  Future<void> write(TransferSocket sink, TransferSecretKey key) async {
    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) {
      e('_AttachmentTransferProtocol#writeBody: file not exist or empty. $path');
      return;
    }

    // first 16 bytes, messageId (uuid)
    final messageIdBytes = Uuid.parseAsByteList(messageId);
    if (messageIdBytes.length != _kUUIDBytesCount) {
      e('_AttachmentTransferProtocol#writeBody: messageIdBytes.length != 16');
      return;
    }

    // calculateEncryptedDataLength
    const kBlockSize = 16;
    final padding = kBlockSize - file.lengthSync() % kBlockSize;
    final encryptedDataLength = file.lengthSync() + padding;

    final hMacCalculator = HMacCalculator(key.hMacKey);

    final iv = generateTransferIv();
    final aesCipher = AesCipher(key: key.aesKey, iv: iv, encrypt: true);

    final header = ByteData(5)
      ..setInt8(0, kTypeFile)
      ..setInt32(1, encryptedDataLength + iv.length + _kUUIDBytesCount);

    sink
      ..add(header.buffer.asUint8List())
      ..add(messageIdBytes)
      ..add(iv);

    hMacCalculator
      ..addBytes(messageIdBytes)
      ..addBytes(iv);

    var actualEncryptedLength = 0;

    final fileStream = file.openRead();

    await for (final bytes in fileStream) {
      aesCipher.update(Uint8List.fromList(bytes), (data) {
        hMacCalculator.addBytes(data);
        sink.add(data);
        actualEncryptedLength += data.length;
      });
      await sink.flush();
    }

    // handle last block
    aesCipher.finish((data) {
      hMacCalculator.addBytes(data);
      sink.add(data);
      actualEncryptedLength += data.length;
    });
    await sink.flush();

    sink.add(hMacCalculator.result);
    if (actualEncryptedLength != encryptedDataLength) {
      e('actualEncryptedLength != encryptedDataLength, '
          '$actualEncryptedLength != $encryptedDataLength');
      throw Exception('write file failed.');
    }
    assert(actualEncryptedLength == encryptedDataLength,
        'actualEncryptedLength != encryptedDataLength, $actualEncryptedLength != $encryptedDataLength');
    await sink.flush();
  }
}

abstract class _TransferPacketBuilder {
  _TransferPacketBuilder(
    this.expectedBodyLength,
    this.hMacKey,
    this.aesKey,
  ) : _hMacCalculator = HMacCalculator(hMacKey);

  final int expectedBodyLength;

  var _writeBodyLength = 0;

  final HMacCalculator _hMacCalculator;

  final Uint8List aesKey;
  final Uint8List hMacKey;

  Uint8List get hMac => _hMacCalculator.result;

  /// return: true if write success, false if write failed.
  bool doWriteBody(Uint8List bytes);

  @nonVirtual
  bool writeBody(Uint8List bytes) {
    final write = doWriteBody(bytes);
    if (!write) {
      i('writeBody, bytes.length: ${bytes.length}');
      return false;
    }
    _hMacCalculator.addBytes(bytes);
    _writeBodyLength += bytes.length;
    assert(_writeBodyLength <= expectedBodyLength);
    return true;
  }

  TransferPacket build();
}

class _TransferJsonPacketBuilder extends _TransferPacketBuilder {
  _TransferJsonPacketBuilder(
      super.expectedBodyLength, super.hMacKey, super.aesKey, this.creator);

  final _body = <int>[];
  final TransferPacket Function(Uint8List jsonBytes) creator;

  @override
  bool doWriteBody(Uint8List bytes) {
    _body.addAll(bytes);
    return true;
  }

  @override
  TransferPacket build() {
    assert(_writeBodyLength == expectedBodyLength);
    final data = Uint8List.fromList(_body);
    final iv = Uint8List.sublistView(data, 0, _kIVBytesCount);
    final jsonData = AesCipher.decrypt(
      key: aesKey,
      iv: iv,
      data: Uint8List.sublistView(data, _kIVBytesCount),
    );
    try {
      return creator(jsonData);
    } catch (error, stacktrace) {
      e('_TransferJsonPacketBuilder#build: $error, $stacktrace \ncontent: ${utf8.decode(jsonData, allowMalformed: true)}');
      rethrow;
    }
  }
}

class _TransferAttachmentPacketBuilder extends _TransferPacketBuilder {
  _TransferAttachmentPacketBuilder(
      super.expectedBodyLength, super.hMacKey, super.aesKey, this.folder);

  final String folder;

  File? _file;
  String? _messageId;
  late AesCipher? _aesCipher;

  @override
  bool doWriteBody(Uint8List bytes) {
    if (_file == null) {
      if (bytes.length < _kUUIDBytesCount + _kIVBytesCount) {
        e('_TransferAttachmentPacketBuilder#doWriteBody: bytes.length is not enough. ${bytes.length}');
        return false;
      }
      final messageId = Uuid.unparse(
        Uint8List.sublistView(bytes, 0, _kUUIDBytesCount),
      );
      _messageId = messageId;

      final iv = Uint8List.sublistView(
        bytes,
        _kUUIDBytesCount,
        _kUUIDBytesCount + _kIVBytesCount,
      );
      _aesCipher = AesCipher(key: aesKey, iv: iv, encrypt: false);

      final tempFileName = const Uuid().v4();
      final file = File(p.join(folder, tempFileName));
      d('write $messageId attachment to: ${file.path}');
      _file = file;
      if (file.existsSync()) {
        file.deleteSync();
      }

      final data =
          Uint8List.sublistView(bytes, _kUUIDBytesCount + _kIVBytesCount);

      file.createSync(recursive: true);
      if (data.isNotEmpty) {
        _processData(data);
      }
      return true;
    } else {
      _processData(bytes);
    }
    return true;
  }

  void _processData(Uint8List encryptedData) {
    _aesCipher!.update(encryptedData, (data) {
      _file!.writeAsBytesSync(data, mode: FileMode.append, flush: true);
    });
  }

  @override
  TransferAttachmentPacket build() {
    _aesCipher!.finish((data) {
      _file!.writeAsBytesSync(data, mode: FileMode.append, flush: true);
    });

    assert(_writeBodyLength == expectedBodyLength,
        'writeBodyLength != expectedBodyLength');
    if (_file == null || _messageId == null) {
      e('_TransferAttachmentPacketBuilder#build: file or messageId is null');
      throw Exception('file or messageId is null');
    }
    d('write $_messageId attachment done, bytes: ${_file!.lengthSync()}');
    return TransferAttachmentPacket(
      messageId: _messageId!,
      path: _file!.path,
    );
  }
}

class TransferProtocolSink implements EventSink<Uint8List> {
  TransferProtocolSink(
    this._sink,
    this.folder,
    this.secretKey, {
    this.onHandleBytes,
  });

  final EventSink<TransferPacket> _sink;
  final String folder;
  final void Function(int)? onHandleBytes;

  final TransferSecretKey secretKey;

  Uint8List get aesKey => secretKey.aesKey;

  Uint8List get hMacKey => secretKey.hMacKey;

  /// The carry-over from the previous chunk.
  Uint8List? _carry;

  _TransferPacketBuilder? _builder;

  @override
  void add(Uint8List event) {
    onHandleBytes?.call(event.length);
    _handleData(event);
  }

  void _handleData(Uint8List event) {
    Uint8List data;
    final carry = _carry;
    if (carry != null) {
      data = Uint8List.fromList(carry + event);
      _carry = null;
    } else {
      data = event;
    }

    var offset = 0;
    while (true) {
      if (_builder == null) {
        if (data.length - offset < 5) {
          _carry = data.sublist(offset);
          return;
        }
        final bytes = data.buffer.asByteData(offset, 5);
        final type = bytes.getInt8(0);
        final bodyLength = bytes.getInt32(1);
        switch (type) {
          case kTypeCommand:
            _builder = _TransferJsonPacketBuilder(
              bodyLength,
              hMacKey,
              aesKey,
              (bytes) => TransferCommandPacket(TransferDataCommand.fromJson(
                json.decode(utf8.decode(bytes)) as Map<String, dynamic>,
              )),
            );
          case kTypeJson:
            _builder = _TransferJsonPacketBuilder(
              bodyLength,
              hMacKey,
              aesKey,
              (bytes) => TransferDataPacket(JsonTransferData.fromJson(
                json.decode(utf8.decode(bytes)) as Map<String, dynamic>,
              )),
            );
          case kTypeFile:
            _builder = _TransferAttachmentPacketBuilder(
                bodyLength, hMacKey, aesKey, folder);
          default:
            _sink.addError('unknown type: $type', StackTrace.current);
            return;
        }
        offset += 5;
      } else {
        final builder = _builder!;
        final need = builder.expectedBodyLength - builder._writeBodyLength;
        if (data.length - offset < need) {
          final write = builder.writeBody(Uint8List.sublistView(data, offset));
          if (!write) {
            _carry = data.sublist(offset);
          }
          return;
        } else {
          final write = builder
              .writeBody(Uint8List.sublistView(data, offset, offset + need));
          assert(write,
              'data length larger than expected, this should not be happen.');

          offset += need;
          // check if left is enough for check hMac
          if (data.length - offset < 32) {
            _carry = data.sublist(offset);
            return;
          }
          // check hMAC
          final hMac = Uint8List.sublistView(data, offset, offset + 32);
          if (!Uint8ListEquality.equals(hMac, builder.hMac)) {
            e('hMac not match. expected ${base64Encode(hMac)}, actually ${base64Encode(builder.hMac)}');
            _sink.addError('hMac check error', StackTrace.current);
            return;
          }
          final packet = builder.build();
          _sink.add(packet);
          _builder = null;
          offset += 32;
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
