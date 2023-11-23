part of 'attachment_util.dart';

Map<String, dynamic> _uploadHeaders = {
  HttpHeaders.contentTypeHeader: 'application/octet-stream',
  HttpHeaders.connectionHeader: 'close',
  'x-amz-acl': 'public-read',
};

extension _CiphertextLengthExtension on int {
  int get ciphertextLength => 16 + (((this ~/ 16) + 1) * 16) + 32;
}

class _AttachmentUploadJobOption {
  _AttachmentUploadJobOption({
    required this.path,
    required this.url,
    required this.keys,
    required this.iv,
    required this.sendPort,
    required this.proxy,
  });

  final String path;
  final String url;
  final List<int>? keys;
  final List<int>? iv;
  final SendPort sendPort;
  final ProxyConfig? proxy;
}

class _AttachmentUploadJob extends _AttachmentJobBase {
  _AttachmentUploadJob({
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
    ProxyConfig? proxy,
    void Function(int count, int total) sendProgress,
  ) async {
    late Isolate? isolate;
    _receivePort = ReceivePort();
    final completer = Completer<List<int>?>();

    _receivePort!.listen((message) {
      if (message is List<int>?) {
        completer.complete(message);
        return;
      }

      switch (message) {
        case (final int received, final int total):
          updateProgress(received, total);
          sendProgress(received, total);
          return;
        case _killMessage:
          isolate?.kill();
          isolate = null;
          if (completer.isCompleted) return;
          completer.completeError(Exception('receive kill message'));
          return;
      }
    });

    isolate = await Isolate.spawn(
        _upload,
        _AttachmentUploadJobOption(
          path: path,
          url: url,
          keys: keys,
          iv: iv,
          sendPort: _receivePort.sendPort,
          proxy: proxy,
        ));

    return completer.future;
  }

  @override
  void cancel() => _receivePort?.sendPort.send(_killMessage);
}

Future<void> _upload(_AttachmentUploadJobOption options) async {
  List<int>? digest;
  final cancelToken = CancelToken();

  final receivePort = ReceivePort();
  options.sendPort.send(receivePort.sendPort);

  receivePort.listen((message) => cancelToken.cancel());

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
    _dio.applyProxy(options.proxy);
    final response = await _dio.putUri(
      Uri.parse(options.url),
      data: uploadStream.handleError((error, stacktrace) {
        e('uploadStream error: $error $stacktrace');
        throw Exception(error);
      }),
      options: Options(
        headers: {
          ..._uploadHeaders,
          HttpHeaders.contentLengthHeader: length,
        },
      ),
      onSendProgress: (int count, int total) =>
          options.sendPort.send((count, total)),
      cancelToken: cancelToken,
    );

    if (response.statusCode != 200) {
      throw Exception('invalid status code: ${response.statusCode}');
    }

    options.sendPort.send(digest);
  } catch (error, stacktrace) {
    e('failed to upload attachment $error, $stacktrace');
    if (error is DioException) {
      e('original stacktrace: ${error.stackTrace}');
    }
    options.sendPort.send(_killMessage);
  }
}
