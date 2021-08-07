part of 'attachment_util.dart';

Map<String, dynamic> _uploadHeaders = {
  HttpHeaders.contentTypeHeader: 'application/octet-stream',
  HttpHeaders.connectionHeader: 'close',
  'x-amz-acl': 'public-read',
};

extension _CiphertextLengthExtension on int {
  int get ciphertextLength => (16 + (((this ~/ 16) + 1) * 16) + 32).toInt();
}

class _AttachmentUploadJobOption {
  _AttachmentUploadJobOption({
    required this.path,
    required this.url,
    required this.keys,
    required this.iv,
    required this.sendPort,
  });

  final String path;
  final String url;
  final List<int>? keys;
  final List<int>? iv;
  final SendPort sendPort;
}

class AttachmentUploadJob implements AttachmentJobBase {
  AttachmentUploadJob({
    required this.path,
    required this.url,
    this.keys,
    this.iv,
  });

  final String path;
  final String url;
  final List<int>? keys;
  final List<int>? iv;

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
          sendPort: _receivePort!.sendPort,
        ));

    return completer.future;
  }

  @override
  void cancel() => _receivePort?.sendPort.send(_killMessage);
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
  if (options.keys != null && options.iv != null) {
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
          ..._uploadHeaders,
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
