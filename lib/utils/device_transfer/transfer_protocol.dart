import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> write(
    TransferSocket sink, {
    required Uint8List aesKey,
    required Uint8List hMacKey,
  });
}

const _kIVBytesCount = 16;

PaddedBlockCipherImpl _createAESCipher({
  required Uint8List aesKey,
  required Uint8List iv,
  required bool encrypt,
}) {
  final cbcCipher = CBCBlockCipher(AESEngine());
  return PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
    ..init(
      encrypt,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(aesKey), iv),
        null,
      ),
    );
}

Future<void> _writeDataToSink({
  required TransferSocket sink,
  required Uint8List aesKey,
  required Uint8List hMacKey,
  required int type,
  required Uint8List data,
}) async {
  final iv = generateTransferIv();

  final aesCipher = _createAESCipher(aesKey: aesKey, iv: iv, encrypt: true);

  final encryptedData = aesCipher.process(data);

  final bodyLength = iv.length + encryptedData.length;

  final header = ByteData(5)
    ..setInt8(0, type)
    ..setInt32(1, bodyLength);

  sink
    ..add(header.buffer.asUint8List())
    ..add(iv)
    ..add(encryptedData);
  final hMac = calculateHMac(hMacKey, encryptedData);
  sink.add(hMac);
  await sink.flush();
}

class TransferDataPacket extends TransferPacket {
  TransferDataPacket(this.data);

  final JsonTransferData data;

  @override
  Future<void> write(
    TransferSocket sink, {
    required Uint8List aesKey,
    required Uint8List hMacKey,
  }) async {
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
      aesKey: aesKey,
      hMacKey: hMacKey,
      type: kTypeJson,
      data: data,
    );
  }
}

class TransferCommandPacket extends TransferPacket {
  TransferCommandPacket(this.command);

  final TransferDataCommand command;

  @override
  Future<void> write(TransferSocket sink,
      {required Uint8List aesKey, required Uint8List hMacKey}) {
    final json = command.toJson();
    final data = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    return _writeDataToSink(
      sink: sink,
      aesKey: aesKey,
      hMacKey: hMacKey,
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
  Future<void> write(
    TransferSocket sink, {
    required Uint8List aesKey,
    required Uint8List hMacKey,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      e('_AttachmentTransferProtocol#writeBody: file not exist. $path');
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

    final iv = generateTransferIv();
    final aesCipher = _createAESCipher(aesKey: aesKey, iv: iv, encrypt: true);

    final header = ByteData(5)
      ..setInt8(0, kTypeFile)
      ..setInt32(1, encryptedDataLength + iv.length + _kUUIDBytesCount);

    sink
      ..add(header.buffer.asUint8List())
      ..add(messageIdBytes)
      ..add(iv);

    final hMacCalculator = HMacCalculator(hMacKey);

    final fileStream = file.openRead();
    await for (final bytes in fileStream) {
      final data = Uint8List.fromList(bytes);
      final encryptedData = aesCipher.process(data);
      hMacCalculator.addBytes(encryptedData);
      sink.add(encryptedData);
      await sink.flush();
    }
    sink.add(hMacCalculator.result);
    await sink.flush();
  }
}

final _lock = Lock(reentrant: true);

Future<void> writePacketToSink(
  TransferSocket sink,
  TransferPacket packet, {
  required Uint8List hMacKey,
  required Uint8List aesKey,
}) =>
    _lock.synchronized(
        () => packet.write(sink, aesKey: aesKey, hMacKey: hMacKey));

abstract class _TransferPacketBuilder {
  _TransferPacketBuilder(
    this.expectedBodyLength,
    this.hMacKey,
    this.aesKey,
  );

  final int expectedBodyLength;

  var _writeBodyLength = 0;

  final Uint8List aesKey;
  final Uint8List hMacKey;

  Uint8List get hMac;

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
  Uint8List get hMac {
    final data = Uint8List.fromList(_body);
    return calculateHMac(hMacKey, Uint8List.sublistView(data, _kIVBytesCount));
  }

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
    final aesCipher = _createAESCipher(aesKey: aesKey, iv: iv, encrypt: false);
    final jsonData = aesCipher.process(
      Uint8List.sublistView(data, _kIVBytesCount),
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
      super.expectedBodyLength, super.hMacKey, super.aesKey, this.folder)
      : _hMacCalculator = HMacCalculator(hMacKey);

  final HMacCalculator _hMacCalculator;

  final String folder;

  File? _file;
  String? _messageId;
  late BlockCipher? _aesCipher;

  @override
  Uint8List get hMac => _hMacCalculator.result;

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
      _aesCipher = _createAESCipher(aesKey: aesKey, iv: iv, encrypt: false);

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
    _hMacCalculator.addBytes(encryptedData);
    final bytes = _aesCipher!.process(encryptedData);
    _file!.writeAsBytesSync(bytes, mode: FileMode.append, flush: true);
  }

  @override
  TransferAttachmentPacket build() {
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
  TransferProtocolSink(this._sink, this.folder, this.secretKey);

  final EventSink<TransferPacket> _sink;
  final String folder;

  final TransferSecretKey secretKey;

  Uint8List get aesKey => secretKey.aesKey;

  Uint8List get hMacKey => secretKey.hMacKey;

  /// The carry-over from the previous chunk.
  Uint8List? _carry;

  _TransferPacketBuilder? _builder;

  @override
  void add(Uint8List event) {
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
            break;
          case kTypeJson:
            _builder = _TransferJsonPacketBuilder(
              bodyLength,
              hMacKey,
              aesKey,
              (bytes) => TransferDataPacket(JsonTransferData.fromJson(
                json.decode(utf8.decode(bytes)) as Map<String, dynamic>,
              )),
            );
            break;
          case kTypeFile:
            _builder = _TransferAttachmentPacketBuilder(
                bodyLength, hMacKey, aesKey, folder);
            break;
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
            _sink.addError(
              'hMac not match. expected ${base64Encode(hMac)}, actually ${base64Encode(builder.hMac)}',
              StackTrace.current,
            );
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
