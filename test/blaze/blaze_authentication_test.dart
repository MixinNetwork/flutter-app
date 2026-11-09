@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/mixin_api_client.dart';
import 'package:flutter_app/workers/job/ack_job.dart';
import 'package:flutter_app/workers/job/flood_job.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  test('Blaze authentication failure confirms the session over HTTP', () async {
    final database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <WebSocket>[];
    final serverSubscription = server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.add(
        gzip.encode(
          utf8.encode(
            jsonEncode({
              'id': 'auth-error',
              'action': 'ERROR',
              'error': {
                'status': 401,
                'code': 401,
                'description': 'Unauthorized',
              },
            }),
          ),
        ),
      );
    });
    final confirmed = Completer<void>();
    final adapter = _AuthenticationAdapter(confirmed);
    final client = Client(accessToken: 'test', httpLogLevel: null);
    client.dio.httpClientAdapter = adapter;
    final httpClient = HttpClient();
    late Blaze blaze;
    addTearDown(() async {
      blaze.dispose();
      client.dio.close();
      for (final socket in sockets) {
        await socket.close();
      }
      await serverSubscription.cancel();
      await server.close(force: true);
      httpClient.close(force: true);
      await database.dispose();
    });

    await HttpOverrides.runZoned(() async {
      blaze = Blaze(
        'user',
        'session',
        base64Encode(List.filled(64, 1)),
        database,
        client,
        'test',
        _UnusedAckJob(),
        _UnusedFloodJob(),
        upgradeGate: ApiUpgradeGate(),
      );
      await blaze.connect();
      await confirmed.future.timeout(const Duration(seconds: 2));
      expect(adapter.meRequests, 1);
      expect(blaze.connectedStateStream.value, isNot(ConnectedState.connected));
    }, createHttpClient: (_) => _RedirectClient(httpClient, server.port));
  });
}

class _RedirectClient implements HttpClient {
  _RedirectClient(this.delegate, this.port);
  final HttpClient delegate;
  final int port;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      delegate.openUrl(method, Uri.http('127.0.0.1:$port', url.path));

  @override
  set findProxy(String Function(Uri url)? value) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthenticationAdapter implements HttpClientAdapter {
  _AuthenticationAdapter(this.confirmed);
  final Completer<void> confirmed;
  int meRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/me') {
      meRequests++;
      if (!confirmed.isCompleted) confirmed.complete();
    }
    return ResponseBody.fromString(
      '{"error":{"status":401,"code":401,"description":"Unauthorized"}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _UnusedAckJob implements AckJob {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedFloodJob implements FloodJob {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
