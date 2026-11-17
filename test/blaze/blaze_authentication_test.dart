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
import 'package:flutter_app/workers/job/ack_job.dart';
import 'package:flutter_app/workers/job/flood_job.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

String? _tokenScope(String? authorization) {
  final payload = authorization!.substring('Bearer '.length).split('.')[1];
  final json = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
  return (jsonDecode(json) as Map<String, dynamic>)['scp'] as String?;
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

class _UnusedAckJob implements AckJob {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedFloodJob implements FloodJob {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
