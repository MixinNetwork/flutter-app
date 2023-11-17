part of 'attachment_util.dart';

const _completeMessage = 'complete';

class _AttachmentDownloadJobOption {
  _AttachmentDownloadJobOption({
    required this.path,
    required this.url,
    required this.keys,
    required this.digest,
    required this.sendPort,
    required this.proxy,
  });

  final String path;
  final String url;
  final List<int>? keys;
  final List<int>? digest;
  final ProxyConfig? proxy;
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
    ProxyConfig? proxy,
    void Function(int count, int total) sendProgress,
  ) async {
    late Isolate? isolate;
    _receivePort = ReceivePort();
    final completer = Completer<void>();

    _receivePort!.listen((message) {
      switch (message) {
        case _completeMessage:
          completer.complete();
          return;
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
        _download,
        _AttachmentDownloadJobOption(
          path: path,
          url: url,
          keys: keys,
          digest: digest,
          sendPort: _receivePort!.sendPort,
          proxy: proxy,
        ));

    return completer.future;
  }

  @override
  void cancel() => _receivePort?.sendPort.send(_killMessage);
}

Future<void> _download(_AttachmentDownloadJobOption options) async {
  final cancelToken = CancelToken();

  final receivePort = ReceivePort();
  options.sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    w('download cancel');
    cancelToken.cancel();
  });

  try {
    var received = 0;
    _dio.applyProxy(options.proxy);
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
        return _stream.handleError((error, stacktrace) {
          e('download error: $error, stack: $stacktrace');
          throw Exception(error);
        }).map((event) {
          received += event.length;
          options.sendPort.send((received, total));
          return event;
        });
      },
      cancelToken: cancelToken,
    );

    if (response.statusCode != 200) throw Error();
    options.sendPort.send(_completeMessage);
  } catch (error, s) {
    e('download error: $error, stack: $s');
    if (error is DioException) {
      e('original stacktrace: ${error.stackTrace}');
    }
    options.sendPort.send(_killMessage);
  }
}

extension _AttachmentDownloadExtension on Dio {
  Future<Response> _download(
    String urlPath,
    String savePath, {
    required Stream<List<int>> Function(Stream<Uint8List> stream, int total)
        transformStream,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  }) async {
    // We set the `responseType` to [ResponseType.STREAM] to retrieve the
    // response stream.
    options ??= Options();
    options
      ..method = 'GET'
      ..responseType = ResponseType.stream;
    Response<ResponseBody> response;
    try {
      response = await request<ResponseBody>(
        urlPath,
        data: data,
        options: options,
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        if (e.response!.requestOptions.receiveDataWhenStatusError) {
          final res = await transformer.transformResponse(
            e.response!.requestOptions..responseType = ResponseType.json,
            e.response!.data as ResponseBody,
          );
          e.response!.data = res;
        } else {
          e.response!.data = null;
        }
      }
      rethrow;
    }

    response.headers = Headers.fromMap(response.data!.headers);

    final file = File(savePath)..createSync(recursive: true);

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
    total = lengthHeader == Headers.contentLengthHeader && compressed
        ? -1
        : int.parse(response.headers.value(lengthHeader) ?? '-1');

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
        }).catchError((Object err, StackTrace? stackTrace) async {
          try {
            await subscription.cancel();
          } finally {
            completer.completeError(
                // ignore: invalid_use_of_internal_member
                DioMixin.assureDioException(err, response.requestOptions));
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
          // ignore: invalid_use_of_internal_member
          completer.completeError(DioMixin.assureDioException(
            e,
            response.requestOptions,
          ));
        }
      },
      onError: (Object e, stack) async {
        try {
          await _closeAndDelete();
        } finally {
          completer.completeError(
              // ignore: invalid_use_of_internal_member
              DioMixin.assureDioException(e, response.requestOptions));
        }
      },
      cancelOnError: true,
    );
    // ignore: unawaited_futures
    cancelToken?.whenCancel.then((_) async {
      await subscription.cancel();
      await _closeAndDelete();
    });

    final receiveTimeout =
        response.requestOptions.receiveTimeout?.inMilliseconds;
    if (receiveTimeout != null && receiveTimeout > 0) {
      future = future
          .timeout(Duration(
        milliseconds: receiveTimeout,
      ))
          .catchError((err, s) async {
        await subscription.cancel();
        await _closeAndDelete();
        if (err is TimeoutException) {
          // ignore: only_throw_errors
          throw DioException(
            requestOptions: response.requestOptions,
            error: 'Receiving data timeout[${receiveTimeout}ms]',
            type: DioExceptionType.receiveTimeout,
          );
        } else {
          w('download error: $err, stack: $s');
          // ignore: throw_of_invalid_type
          throw err;
        }
      });
    }
    // ignore: invalid_use_of_internal_member
    return DioMixin.listenCancelForAsyncTask(cancelToken, future);
  }
}
