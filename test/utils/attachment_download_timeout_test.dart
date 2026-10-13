import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_app/utils/attachment/attachment_util.dart';
import 'package:flutter_test/flutter_test.dart';

Future<HttpServer> _serve(List<Duration> gaps) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    request.response
      ..bufferOutput = false
      ..contentLength = gaps.length;
    for (var i = 0; i < gaps.length; i++) {
      await Future<void>.delayed(gaps[i]);
      request.response.add([i]);
      await request.response.flush();
    }
    await request.response.close();
  });
  return server;
}

void main() {
  final dio = Dio(BaseOptions(receiveTimeout: const Duration(seconds: 1)));
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('download'));
  tearDown(() => dir.delete(recursive: true));

  test('finishes a download that takes longer than receiveTimeout', () async {
    final server = await _serve(
      List.filled(5, const Duration(milliseconds: 400)),
    );
    addTearDown(() => server.close(force: true));

    await downloadAttachmentStream(
      dio,
      'http://127.0.0.1:${server.port}/',
      '${dir.path}/file',
    );

    expect(File('${dir.path}/file').readAsBytesSync(), [0, 1, 2, 3, 4]);
  });

  test('times out when no data arrives within receiveTimeout', () async {
    final server = await _serve(const [Duration.zero, Duration(seconds: 3)]);
    addTearDown(() => server.close(force: true));

    await expectLater(
      downloadAttachmentStream(
        dio,
        'http://127.0.0.1:${server.port}/',
        '${dir.path}/file',
      ),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.receiveTimeout,
        ),
      ),
    );
    expect(File('${dir.path}/file').existsSync(), isFalse);
  });
}
