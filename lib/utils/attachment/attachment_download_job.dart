part of 'attachment_util.dart';

const _completeMessage = 'complete';

class _AttachmentDownloadJobOption {
  _AttachmentDownloadJobOption({
    required this.path,
    required this.url,
    required this.keys,
    required this.digest,
    required this.sendPort,
  });

  final String path;
  final String url;
  final List<int>? keys;
  final List<int>? digest;
  final SendPort sendPort;
}

class _AttachmentDownloadJob extends _AttachmentJobBase {
  _AttachmentDownloadJob({
    required this.path,
    required this.url,
    this.keys,
    this.digest,
  });

  final String path;
  final String url;
  final List<int>? keys;
  final List<int>? digest;

  late final ReceivePort? _receivePort;

  Future<void> download(
    void Function(int count, int total) sendProgress,
  ) async {
    late Isolate? isolate;
    _receivePort = ReceivePort();
    final completer = Completer<void>();

    _receivePort!.listen((message) {
      if (message == _killMessage) {
        isolate?.kill();
        isolate = null;
        if (completer.isCompleted) return;
        completer.completeError(Exception('receive kill message'));
      }

      if (message is Tuple2<int, int>) {
        updateProgress(message.item1, message.item2);
        sendProgress(message.item1, message.item2);
        return;
      }
      if (message == _completeMessage) {
        completer.complete();
      }
    });

    isolate = await Isolate.spawn(
        _download,
        _AttachmentDownloadJobOption(
          path: path,
          url: url,
          keys: keys,
          digest: digest,
          sendPort: _receivePort!.sendPort,
        ));

    return completer.future;
  }

  @override
  void cancel() => _receivePort?.sendPort.send(_killMessage);
}

Future<void> _download(_AttachmentDownloadJobOption options) async {
  final CancelToken? cancelToken = CancelToken();

  final receivePort = ReceivePort();
  options.sendPort.send(receivePort.sendPort);

  receivePort.listen((message) => cancelToken?.cancel());

  try {
    var received = 0;
    final response = await _dio._download(
      options.url,
      options.path,
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'application/octet-stream',
        },
      ),
      transformStream: (Stream<Uint8List> stream, int total) {
        var _stream = stream.cast<List<int>>();
        if (options.keys != null && options.digest != null) {
          _stream = _stream.decrypt(options.keys!, options.digest!, total);
        }
        return _stream.doOnData((event) {
          received += event.length;
          options.sendPort.send(Tuple2(received, total));
        });
      },
      cancelToken: cancelToken,
    );

    if (response.statusCode != 200) throw Error();
    options.sendPort.send(_completeMessage);
  } catch (e) {}
  options.sendPort.send(_killMessage);
}

extension _AttachmentDownloadExtension on Dio {
  Future<Response> _download(
    String urlPath,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
    required Stream<List<int>> Function(Stream<Uint8List> stream, int total)
        transformStream,
  }) async {
    // We set the `responseType` to [ResponseType.STREAM] to retrieve the
    // response stream.
    options ??= DioMixin.checkOptions('GET', options);

    // Receive data with stream.
    options.responseType = ResponseType.stream;
    Response<ResponseBody> response;
    try {
      response = await request<ResponseBody>(
        urlPath,
        data: data,
        options: options,
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(),
      );
    } on DioError catch (e) {
      if (e.type == DioErrorType.response) {
        if (e.response!.requestOptions.receiveDataWhenStatusError == true) {
          final res = await transformer.transformResponse(
            e.response!.requestOptions..responseType = ResponseType.json,
            e.response!.data,
          );
          e.response!.data = res;
        } else {
          e.response!.data = null;
        }
      }
      rethrow;
    }

    response.headers = Headers.fromMap(response.data!.headers);

    final file = File(savePath.toString())..createSync(recursive: true);

    // Shouldn't call file.writeAsBytesSync(list, flush: flush),
    // because it can write all bytes by once. Consider that the
    // file with a very big size(up 1G), it will be expensive in memory.
    var raf = file.openSync(mode: FileMode.write);

    //Create a Completer to notify the success/error state.
    final completer = Completer<Response>();
    var future = completer.future;

    var compressed = false;
    var total = 0;
    final contentEncoding =
        response.headers.value(Headers.contentEncodingHeader);
    if (contentEncoding != null) {
      compressed = ['gzip', 'deflate', 'compress'].contains(contentEncoding);
    }
    if (lengthHeader == Headers.contentLengthHeader && compressed) {
      total = -1;
    } else {
      total = int.parse(response.headers.value(lengthHeader) ?? '-1');
    }

    // Stream<Uint8List>
    final stream = transformStream(response.data!.stream, total);

    late StreamSubscription subscription;
    Future? asyncWrite;
    var closed = false;
    Future _closeAndDelete() async {
      if (!closed) {
        closed = true;
        await asyncWrite;
        await raf.close();
        if (deleteOnError) await file.delete();
      }
    }

    subscription = stream.listen(
      (data) {
        subscription.pause();
        // Write file asynchronously
        asyncWrite = raf.writeFrom(data).then((_raf) {
          raf = _raf;
          if (cancelToken == null || !cancelToken.isCancelled) {
            subscription.resume();
          }
        }).catchError((err, stackTrace) async {
          try {
            await subscription.cancel();
          } finally {
            completer.completeError(DioMixin.assureDioError(
                err, response.requestOptions, stackTrace));
          }
        });
      },
      onDone: () async {
        try {
          await asyncWrite;
          closed = true;
          await raf.close();
          completer.complete(response);
        } catch (e) {
          completer.completeError(DioMixin.assureDioError(
            e,
            response.requestOptions,
          ));
        }
      },
      onError: (e) async {
        try {
          await _closeAndDelete();
        } finally {
          completer.completeError(DioMixin.assureDioError(
            e,
            response.requestOptions,
          ));
        }
      },
      cancelOnError: true,
    );
    // ignore: unawaited_futures
    cancelToken?.whenCancel.then((_) async {
      await subscription.cancel();
      await _closeAndDelete();
    });

    if (response.requestOptions.receiveTimeout > 0) {
      future = future
          .timeout(Duration(
        milliseconds: response.requestOptions.receiveTimeout,
      ))
          .catchError((err) async {
        await subscription.cancel();
        await _closeAndDelete();
        if (err is TimeoutException) {
          throw DioError(
            requestOptions: response.requestOptions,
            error:
                'Receiving data timeout[${response.requestOptions.receiveTimeout}ms]',
            type: DioErrorType.receiveTimeout,
          );
        } else {
          throw err;
        }
      });
    }
    return DioMixin.listenCancelForAsyncTask(cancelToken, future);
  }
}
