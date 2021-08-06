import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:chunked_stream/chunked_stream.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as cr;
import 'package:dio/dio.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:tuple/tuple.dart';

const int _blockSize = 64 * 1024;
const _killMessage = 'kill';

extension _EncryptStreamExtension on Stream<List<int>> {
  Stream<List<int>> encrypt(
    List<int> keys,
    List<int> iv,
    void Function(List<int>) digestCallback,
  ) =>
      bufferChunkedStream(this, bufferSize: _blockSize)
          ._encrypt(keys, iv, digestCallback);

  Stream<List<int>> _encrypt(
    List<int> keys,
    List<int> iv,
    void Function(List<int>) digestCallback,
  ) {
    if (isBroadcast) throw ArgumentError('Stream must be not broadcast.');

    final aesKey = keys.sublist(0, 32);
    final macKey = keys.sublist(32, 64);
    final mac = cr.Hmac(cr.sha256, macKey);
    final macOutput = AccumulatorSink<cr.Digest>();
    final macSink = mac.startChunkedConversion(macOutput);

    final cbcCipher = CBCBlockCipher(AESFastEngine());
    var _aesCipher = _getAesCipher(cbcCipher, aesKey, iv);

    final digestOutput = AccumulatorSink<cr.Digest>();
    final digestSink = cr.sha256.startChunkedConversion(digestOutput);

    macSink.add(iv);
    digestSink.add(iv);

    final controller = StreamController<List<int>>()..add(iv);

    void close() {
      macSink.close();
      digestSink.close();
    }

    void addError(Object error, [StackTrace? stackTrace]) {
      close();
      controller.addError(error, stackTrace);
    }

    controller.onListen = () {
      final subscription = listen(
        null,
        onError: addError,
        onDone: () {
          macSink.close();
          final mac = macOutput.events.single.bytes;
          digestSink
            ..add(mac)
            ..close();
          controller
            ..add(mac)
            ..close();
          digestCallback(digestOutput.events.single.bytes);
        },
      );

      final pause = subscription.pause;
      final resume = subscription.resume;

      var lastBlock = iv;
      Future<List<int>> process(List<int> event) async {
        Uint8List ciphertext;
        _aesCipher = _getAesCipher(cbcCipher, aesKey, lastBlock);
        final input = Uint8List.fromList(event);
        if (event.length < _blockSize) {
          ciphertext = _aesCipher.process(input);
        } else {
          ciphertext = Uint8List(input.lengthInBytes);
          for (var offset = 0; offset < input.lengthInBytes;) {
            offset +=
                _aesCipher.processBlock(input, offset, ciphertext, offset);
          }
        }
        macSink.add(ciphertext);
        digestSink.add(ciphertext);

        final result = ciphertext.toList();
        lastBlock = result.sublist(result.length - 16, result.length);
        return result;
      }

      subscription.onData((List<int> event) {
        pause();
        process(event)
            .then(controller.add, onError: addError)
            .whenComplete(resume);
      });
      controller
        ..onCancel = () {
          close();
          subscription.cancel();
        }
        ..onPause = pause
        ..onResume = resume;
    };
    return controller.stream;
  }
}

extension _CiphertextLengthExtension on int {
  int get ciphertextLength => (16 + (((this ~/ 16) + 1) * 16) + 32).toInt();
}

final _dio = Dio(BaseOptions(
  connectTimeout: 150 * 1000,
  receiveTimeout: 150 * 1000,
));

Map<String, dynamic> _headers = {
  HttpHeaders.contentTypeHeader: 'application/octet-stream',
  HttpHeaders.connectionHeader: 'close',
  'x-amz-acl': 'public-read',
};

PaddedBlockCipher _getAesCipher(
  CBCBlockCipher cbcCipher,
  List<int> aesKey,
  List<int> iv,
) {
  final ivParams = ParametersWithIV<KeyParameter>(
      KeyParameter(Uint8List.fromList(aesKey)), Uint8List.fromList(iv));
  final paddingParams =
      // ignore: prefer_void_to_null
      PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ivParams, null);
  return PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
    ..init(true, paddingParams);
}

class _AttachmentUploadJobOption {
  _AttachmentUploadJobOption({
    required this.path,
    required this.url,
    required this.keys,
    required this.iv,
    required this.isSignal,
    required this.sendPort,
  });

  final String path;
  final String url;
  final List<int>? keys;
  final List<int>? iv;
  final bool isSignal;
  final SendPort sendPort;
}

class AttachmentUploadJob {
  AttachmentUploadJob({
    required this.path,
    required this.url,
    this.keys,
    this.iv,
    required this.isSignal,
  });

  final String path;
  final String url;
  final List<int>? keys;
  final List<int>? iv;
  final bool isSignal;

  late final ReceivePort? _receivePort;

  Future<List<int>?> upload(
    void Function(int count, int total) sendProgress,
  ) async {
    late Isolate? isolate;
    _receivePort = ReceivePort();
    final completer = Completer<List<int>>();

    _receivePort!.listen((message) {
      if (message == _killMessage) {
        isolate?.kill();
        isolate = null;
        if (completer.isCompleted) return;
        completer.completeError(Exception('receive kill message'));
      }

      if (message is Tuple2<int, int>) {
        sendProgress(message.item1, message.item2);
        return;
      }
      if (message is List<int>?) {
        completer.complete(message);
      }
    });

    isolate = await Isolate.spawn(
        _upload,
        _AttachmentUploadJobOption(
          path: path,
          url: url,
          keys: keys,
          iv: iv,
          isSignal: isSignal,
          sendPort: _receivePort!.sendPort,
        ));

    return completer.future;
  }

  void cancel() {
    _receivePort?.sendPort.send(_killMessage);
  }
}

Future<void> _upload(_AttachmentUploadJobOption options) async {
  List<int>? digest;
  final CancelToken? cancelToken = CancelToken();

  final receivePort = ReceivePort();
  options.sendPort.send(receivePort.sendPort);

  receivePort.listen((message) => cancelToken?.cancel());

  final file = File(options.path);

  Stream<List<int>> uploadStream;
  int length;
  if (options.isSignal && options.keys != null && options.iv != null) {
    uploadStream =
        file.openRead().encrypt(options.keys!, options.iv!, (_digest) {
      digest = _digest;
    });

    length = (await file.length()).ciphertextLength;
  } else {
    uploadStream = file.openRead();
    length = await file.length();
  }

  try {
    final response = await _dio.putUri(
      Uri.parse(options.url),
      data: uploadStream,
      options: Options(
        headers: {
          ..._headers,
          HttpHeaders.contentLengthHeader: length,
        },
      ),
      onSendProgress: (int count, int total) =>
          options.sendPort.send(Tuple2(count, total)),
      cancelToken: cancelToken,
    );

    if (response.statusCode != 200) throw Error();

    options.sendPort.send(digest);
    options.sendPort.send(_killMessage);
  } catch (_) {
    options.sendPort.send(_killMessage);
  }
}
