@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/constants/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/mixin_api_client.dart';
import 'package:flutter_app/utils/proxy.dart';
import 'package:flutter_app/workers/job/ack_job.dart';
import 'package:flutter_app/workers/job/flood_job.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  for (final (sessionValid, disposeDuringConfirmation, loginByPhoneNumber) in [
    (false, false, false),
    (true, false, false),
    (true, true, false),
    (false, false, true),
  ]) {
    test(
      loginByPhoneNumber
          ? 'Blaze signs phone number login sessions with FULL scope'
          : disposeDuringConfirmation
          ? 'Disposing Blaze during session confirmation prevents reconnect'
          : sessionValid
          ? 'Blaze authentication retries are delayed and use fresh tokens'
          : 'Blaze authentication failure confirms the session over HTTP',
      () async {
        final database = Database(
          MixinDatabase(NativeDatabase.memory()),
          FtsDatabase(NativeDatabase.memory()),
        );
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final sockets = <WebSocket>[];
        final tokens = <String?>[];
        final deviceIds = <String?>[];
        final connectionTimes = <Duration>[];
        final stopwatch = Stopwatch()..start();
        final secondConnection = Completer<void>();
        final serverSubscription = server.listen((request) async {
          final socket = await WebSocketTransformer.upgrade(request);
          sockets.add(socket);
          connectionTimes.add(stopwatch.elapsed);
          tokens.add(request.headers.value(HttpHeaders.authorizationHeader));
          deviceIds.add(request.headers.value('Mixin-Device-Id'));
          if (sockets.length == 2) secondConnection.complete();
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
        final adapter = _AuthenticationAdapter(
          confirmed,
          sessionValid: sessionValid,
        );
        if (disposeDuringConfirmation) adapter.responseGate = Completer<void>();
        final client = Client(accessToken: 'test', httpLogLevel: null);
        client.dio.httpClientAdapter = adapter;
        final httpClient = HttpClient();
        late Blaze blaze;
        var disposed = false;
        addTearDown(() async {
          if (!disposed) blaze.dispose();
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
            'test-device',
            _UnusedAckJob(),
            _UnusedFloodJob(),
            loginByPhoneNumber: loginByPhoneNumber,
            upgradeGate: ApiUpgradeGate(),
          );
          await blaze.connect();
          await confirmed.future.timeout(const Duration(seconds: 2));
          if (disposeDuringConfirmation) {
            blaze.dispose();
            disposed = true;
            adapter.responseGate!.complete();
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
          expect(adapter.meRequests, 1);
          expect(sockets, hasLength(1));
          expect(deviceIds.first, 'test-device');
          expect(
            _tokenScope(tokens.first),
            loginByPhoneNumber ? scpFull : scp,
          );
          expect(
            blaze.connectedStateStream.value,
            isNot(ConnectedState.connected),
          );
          if (disposeDuringConfirmation) {
            expect(
              blaze.connectedStateStream.value,
              ConnectedState.disconnected,
            );
            return;
          }
          if (sessionValid) {
            await secondConnection.future.timeout(const Duration(seconds: 7));
            expect(
              connectionTimes[1] - connectionTimes[0],
              greaterThanOrEqualTo(const Duration(seconds: 5)),
            );
            // Compare without printing either Authorization header on failure.
            expect(
              tokens[0] == tokens[1],
              isFalse,
              reason: 'A rejected Blaze token must not be reused',
            );
            await Future<void>.delayed(const Duration(milliseconds: 200));
            expect(sockets, hasLength(2));
            expect(adapter.meRequests, 2);
          }
        }, createHttpClient: (_) => _RedirectClient(httpClient, server.port));
      },
    );
  }

  test('Blaze signs a new token when it reconnects after a drop', () async {
    final database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <WebSocket>[];
    final tokens = <String?>[];
    final requestIds = <String?>[];
    final secondConnection = Completer<void>();
    final serverSubscription = server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      tokens.add(request.headers.value(HttpHeaders.authorizationHeader));
      requestIds.add(request.headers.value('X-Request-Id'));
      if (sockets.length == 2) {
        secondConnection.complete();
        return;
      }
      // A message without an error marks the connection as connected; then
      // the server drops it, as the network or the server can.
      socket.add(
        gzip.encode(
          utf8.encode(
            jsonEncode({'id': 'ok', 'action': 'LIST_PENDING_MESSAGES'}),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await socket.close();
    });
    final adapter = _ConnectedAdapter(
      _AuthenticationAdapter(Completer<void>(), sessionValid: true),
    );
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
        'test-device',
        _UnusedAckJob(),
        _UnusedFloodJob(),
        loginByPhoneNumber: false,
        upgradeGate: ApiUpgradeGate(),
      );
      await blaze.connect();
      await secondConnection.future.timeout(const Duration(seconds: 8));
      // Check without printing either Authorization header on failure.
      for (final token in tokens) {
        expect(
          token?.startsWith('Bearer ') == true && token!.length > 7,
          isTrue,
          reason: 'Each connection must send a bearer token',
        );
      }
      expect(
        tokens[0] == tokens[1],
        isFalse,
        reason: 'Each connection must sign its own token',
      );
      for (var i = 0; i < 2; i++) {
        expect(requestIds[i], isNotNull);
        expect(
          _tokenClaim(tokens[i], 'jti'),
          requestIds[i],
          reason: 'The server rejects a jti that is not the X-Request-Id',
        );
      }
    }, createHttpClient: (_) => _RedirectClient(httpClient, server.port));
  });

  test(
    'Blaze handshake HTTP 202 confirms upgrade over HTTP and stops reconnecting',
    () async {
      final database = Database(
        MixinDatabase(NativeDatabase.memory()),
        FtsDatabase(NativeDatabase.memory()),
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var handshakeAttempts = 0;
      final serverSubscription = server.listen((request) async {
        handshakeAttempts++;
        request.response
          ..statusCode = HttpStatus.accepted
          ..headers.contentType = ContentType.json
          ..write(
            '{"error":{"status":202,"code":10006,"description":"Update required."}}',
          );
        await request.response.close();
      });

      final upgradeTriggered = Completer<void>();
      var upgradeCalls = 0;
      late Blaze blaze;
      final upgradeGate = ApiUpgradeGate(
        onRequired: () {
          upgradeCalls++;
          blaze.stopForUpgrade();
          if (!upgradeTriggered.isCompleted) upgradeTriggered.complete();
        },
      );

      final adapter = _OldVersionAdapter();
      final client = Client(
        accessToken: 'test',
        httpLogLevel: null,
        interceptors: [
          InterceptorsWrapper(
            onError: (error, handler) {
              final mixinError = error is MixinApiError ? error.error : null;
              if (mixinError is MixinError && mixinError.code == oldVersion) {
                upgradeGate.require();
              }
              handler.next(error);
            },
          ),
        ],
      );
      client.dio.httpClientAdapter = adapter;
      final httpClient = HttpClient();

      addTearDown(() async {
        blaze.dispose();
        client.dio.close();
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
          'test-device',
          _UnusedAckJob(),
          _UnusedFloodJob(),
          loginByPhoneNumber: false,
          upgradeGate: upgradeGate,
        );
        await blaze.connect();
        await upgradeTriggered.future.timeout(const Duration(seconds: 5));
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(handshakeAttempts, 1);
        expect(adapter.meRequests, 1);
        expect(upgradeGate.isRequired, isTrue);
        expect(upgradeCalls, 1);
        expect(blaze.connectedStateStream.value, ConnectedState.disconnected);
      }, createHttpClient: (_) => _RedirectClient(httpClient, server.port));
    },
  );

  test(
    'Blaze aborts a stalled /me probe socket and retries on the next HTTP 202',
    () async {
      final database = Database(
        MixinDatabase(NativeDatabase.memory()),
        FtsDatabase(NativeDatabase.memory()),
      );
      final wsServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var handshakeAttempts = 0;
      final wsServerSubscription = wsServer.listen((request) async {
        handshakeAttempts++;
        request.response
          ..statusCode = HttpStatus.accepted
          ..headers.contentType = ContentType.json
          ..write(
            '{"error":{"status":202,"code":10006,"description":"Update required."}}',
          );
        await request.response.close();
      });

      final apiServer = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      var meConnections = 0;
      final firstMeSocketClosed = Completer<void>();
      final openSockets = <Socket>[];
      final apiServerSubscription = apiServer.listen((socket) {
        meConnections++;
        openSockets.add(socket);
        final attempt = meConnections;
        if (attempt == 1) {
          socket.listen(
            (_) {},
            onDone: () {
              if (!firstMeSocketClosed.isCompleted) {
                firstMeSocketClosed.complete();
              }
            },
          );
          return;
        }
        const body =
            '{"error":{"status":202,"code":10006,"description":"Update required."}}';
        socket.write(
          'HTTP/1.1 202 Accepted\r\n'
          'content-type: application/json\r\n'
          'content-length: ${body.length}\r\n'
          'connection: close\r\n\r\n'
          '$body',
        );
        unawaited(socket.flush().then((_) => socket.close()));
      });

      final upgradeTriggered = Completer<void>();
      var upgradeCalls = 0;
      late Blaze blaze;
      final upgradeGate = ApiUpgradeGate(
        onRequired: () {
          upgradeCalls++;
          blaze.stopForUpgrade();
          if (!upgradeTriggered.isCompleted) upgradeTriggered.complete();
        },
      );

      final client = Client(
        accessToken: 'test',
        httpLogLevel: null,
        interceptors: [
          InterceptorsWrapper(
            onError: (error, handler) {
              final mixinError = error is MixinApiError ? error.error : null;
              if (mixinError is MixinError && mixinError.code == oldVersion) {
                upgradeGate.require();
              }
              handler.next(error);
            },
          ),
        ],
      );
      client.dio.options.baseUrl = 'http://127.0.0.1:${apiServer.port}';
      final apiHttpClient = HttpClient();
      client.dio.httpClientAdapter = AbortableHttpClientAdapter(
        IOClient(apiHttpClient),
      );
      final wsHttpClient = HttpClient();

      addTearDown(() async {
        blaze.dispose();
        client.dio.close(force: true);
        apiHttpClient.close(force: true);
        wsHttpClient.close(force: true);
        for (final socket in openSockets) {
          socket.destroy();
        }
        await wsServerSubscription.cancel();
        await wsServer.close(force: true);
        await apiServerSubscription.cancel();
        await apiServer.close();
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
          'test-device',
          _UnusedAckJob(),
          _UnusedFloodJob(),
          loginByPhoneNumber: false,
          upgradeGate: upgradeGate,
          handshakeConfirmTimeout: const Duration(milliseconds: 100),
        );
        await blaze.connect();
        await firstMeSocketClosed.future.timeout(const Duration(seconds: 2));
        await upgradeTriggered.future.timeout(const Duration(seconds: 8));
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(handshakeAttempts, 2);
        expect(meConnections, 2);
        expect(upgradeGate.isRequired, isTrue);
        expect(upgradeCalls, 1);
        expect(blaze.connectedStateStream.value, ConnectedState.disconnected);
      }, createHttpClient: (_) => _RedirectClient(wsHttpClient, wsServer.port));
    },
  );
}

String? _tokenScope(String? authorization) => _tokenClaim(authorization, 'scp');

String? _tokenClaim(String? authorization, String claim) {
  final payload = authorization!.substring('Bearer '.length).split('.')[1];
  final json = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
  return (jsonDecode(json) as Map<String, dynamic>)[claim] as String?;
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
  String? get userAgent => delegate.userAgent;

  @override
  set userAgent(String? value) => delegate.userAgent = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthenticationAdapter implements HttpClientAdapter {
  _AuthenticationAdapter(this.confirmed, {required this.sessionValid});
  final bool sessionValid;
  final Completer<void> confirmed;
  int meRequests = 0;
  Completer<void>? responseGate;

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
    await responseGate?.future;
    if (sessionValid) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'user_id': 'user',
            'identity_number': '123',
            'session_id': 'session',
            'created_at': '2026-01-01T00:00:00Z',
            for (final key in [
              'phone',
              'biography',
              'mute_until',
              'pin_token',
              'pin_token_base64',
              'code_id',
              'code_url',
              'device_status',
              'receive_message_source',
              'accept_conversation_source',
              'accept_search_source',
              'fiat_currency',
              'tip_key_base64',
            ])
              key: '',
            for (final key in [
              'is_verified',
              'is_scam',
              'has_safe',
              'has_pin',
              'has_emergency_contact',
            ])
              key: false,
            'transfer_notification_threshold': 0,
            'transfer_confirmation_threshold': 0,
            'tip_counter': 0,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
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

// Answers /me as a valid session and every other request, such as the
// offset refresh after connecting, with an empty list.
class _ConnectedAdapter implements HttpClientAdapter {
  _ConnectedAdapter(this.me);
  final _AuthenticationAdapter me;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (options.path == '/me') {
      return me.fetch(options, requestStream, cancelFuture);
    }
    return Future.value(
      ResponseBody.fromString(
        '{"data":[]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

class _OldVersionAdapter implements HttpClientAdapter {
  int meRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/me') {
      meRequests++;
    }
    return ResponseBody.fromString(
      '{"error":{"status":202,"code":10006,"description":"Update required."}}',
      202,
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
