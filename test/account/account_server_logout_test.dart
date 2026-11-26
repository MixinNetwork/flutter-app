@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Sticker;
import 'package:flutter_app/ui/provider/multi_auth_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/utils/hive_key_values.dart';
import 'package:flutter_app/utils/mixin_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rhttp/src/rust/api/client.dart' as rust;
import 'package:rhttp/src/rust/frb_generated.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  RustLib.initMock(api: _UnusedRustApi());
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('desktop_webview_window'),
        (_) async => null,
      );

  late _TestAccountServer server;
  late _AuthNotifier auth;
  late _RevokedSessionAdapter adapter;
  late Database database;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp('logout-test-');
    mixinDocumentsDirectory = directory;
    database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    auth = _AuthNotifier();
    adapter = _RevokedSessionAdapter();
    server = _TestAccountServer(
      multiAuthNotifier: auth,
      settingChangeNotifier: _UnusedSettings(),
      database: database,
      currentConversationId: () => null,
      adapter: adapter,
    );
    addTearDown(() async {
      server.checkSignalKeyTimer?.cancel();
      server.client.dio.close(force: true);
      AccountServer.sid = null;
      await clearKeyValues();
      await database.dispose();
      await directory.delete(recursive: true);
      auth.dispose();
    });
    await server.initServer(
      'user',
      'session',
      '123',
      base64Encode(List.filled(64, 1)),
    );
  });

  test(
    'manual logout completes when the session has already been revoked',
    () async {
      await expectLater(
        server.signOutAndClear().timeout(const Duration(seconds: 2)),
        completes,
      );
      expect(adapter.logoutRequests, 1);
      expect(auth.signOutCount, 1);
    },
  );

  test(
    'HTTP authentication errors clear login without revoking again',
    () async {
      await Future.wait([
        expectLater(
          server.client.accountApi.getMe(),
          throwsA(isA<MixinApiError>()),
        ),
        expectLater(
          server.client.accountApi.getMe(),
          throwsA(isA<MixinApiError>()),
        ),
      ]);
      await server.signOutAndClear();
      expect(adapter.logoutRequests, 0);
      expect(auth.signOutCount, 1);
    },
  );

  test('concurrent logout calls share one cleanup', () async {
    final first = server.signOutAndClear();
    final second = server.signOutAndClear();
    expect(identical(first, second), isTrue);
    await Future.wait([first, second]);
    expect(adapter.logoutRequests, 1);
    expect(auth.signOutCount, 1);
  });

  test('concurrent sticker refreshes share one request', () async {
    final gate = Completer<void>();
    adapter.stickerAlbumsGate = gate.future;

    final refreshes = [
      for (var i = 0; i < 5; i++) server.refreshSticker(force: i.isEven),
    ];
    await adapter.stickerAlbumsRequested.future;
    // Let the other calls reach the adapter if they send their own request.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(adapter.stickerAlbumsRequests, 1);

    gate.complete();
    await Future.wait(refreshes);
    expect(adapter.stickerAlbumsRequests, 1);

    await server.refreshSticker();
    expect(adapter.stickerAlbumsRequests, 1);
    await server.refreshSticker(force: true);
    expect(adapter.stickerAlbumsRequests, 2);
  });

  test('the first favorite sticker fetches only its album', () async {
    final sticker = Sticker.fromJson(const {
      'sticker_id': 'added',
      'album_id': 'personal',
      'name': '',
      'asset_url': '',
      'asset_type': 'image',
      'asset_width': 1,
      'asset_height': 1,
      'created_at': '2026-01-01T00:00:00Z',
    });

    await server.saveFavoriteSticker(sticker);

    final db = database.mixinDatabase;
    expect(adapter.albumRequests, 1);
    expect(adapter.stickerAlbumsRequests, 0);
    expect(
      (await database.stickerAlbumDao.personalAlbum().getSingle()).albumId,
      'personal',
    );
    expect((await db.select(db.stickers).get()).single.stickerId, 'added');
    expect(
      (await db.select(db.stickerRelationships).get()).single.albumId,
      'personal',
    );
  });

  test('server clock skew does not clear login', () async {
    adapter.serverTime = DateTime.now().add(const Duration(minutes: 10));
    await expectLater(
      server.client.accountApi.getMe(),
      throwsA(isA<MixinApiError>()),
    );
    expect(auth.signOutCount, 0);
    expect(adapter.logoutRequests, 0);
  });

  test(
    'HTTP 10006 sets isUpdateRequired and blocks subsequent requests',
    () async {
      adapter.errorCode = oldVersion;
      await expectLater(
        server.client.accountApi.getMe(),
        throwsA(isA<MixinApiError>()),
      );
      expect(server.isUpdateRequired.valueOrNull, isTrue);
      expect(adapter.meRequests, 1);

      await expectLater(
        server.client.accountApi.getMe(),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<ApiUpgradeRequiredException>(),
          ),
        ),
      );
      expect(adapter.meRequests, 1);
    },
  );
}

class _TestAccountServer extends AccountServer {
  _TestAccountServer({
    required super.multiAuthNotifier,
    required super.settingChangeNotifier,
    required super.database,
    required super.currentConversationId,
    required this.adapter,
  });

  final HttpClientAdapter adapter;

  @override
  Future<void> checkSignalKeys() async {
    client.dio.httpClientAdapter = adapter;
    client.dio.interceptors.removeWhere(
      (interceptor) => interceptor is MixinLogInterceptor,
    );
    // Stop initialization before starting background workers.
    final options = RequestOptions(path: '/signal/keys');
    throw MixinApiError(
      requestOptions: options,
      response: Response(requestOptions: options),
      error: MixinError(500, 500, 'Initialization stopped for test'),
    );
  }
}

class _RevokedSessionAdapter implements HttpClientAdapter {
  int logoutRequests = 0;
  int meRequests = 0;
  int stickerAlbumsRequests = 0;
  Future<void>? stickerAlbumsGate;
  final stickerAlbumsRequested = Completer<void>();
  int albumRequests = 0;
  int errorCode = authentication;
  DateTime? serverTime;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/logout') logoutRequests++;
    if (options.path == '/me') meRequests++;
    if (options.path == '/albums/personal') {
      albumRequests++;
      return ResponseBody.fromString(
        '{"data":{"album_id":"personal","name":"","icon_url":"",'
        '"created_at":"2026-01-01T00:00:00Z",'
        '"update_at":"2026-01-01T00:00:00Z","user_id":"user",'
        '"category":"PERSONAL","description":"","is_verified":false}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path == '/stickers/albums') {
      stickerAlbumsRequests++;
      if (!stickerAlbumsRequested.isCompleted) {
        stickerAlbumsRequested.complete();
      }
      await stickerAlbumsGate;
      return ResponseBody.fromString(
        '{"data":[]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    // Bound the broken implementation's recursive requests without allowing
    // cleanup to complete, so the test reports the actual logout timeout.
    if (logoutRequests > 3) return Completer<ResponseBody>().future;
    final status = errorCode == oldVersion ? 202 : 401;
    final description = errorCode == oldVersion
        ? 'Update required.'
        : 'Unauthorized';
    return ResponseBody.fromString(
      '{"error":{"status":$status,"code":$errorCode,"description":"$description"}}',
      errorCode == oldVersion ? 202 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (serverTime != null)
          'x-server-time': ['${serverTime!.microsecondsSinceEpoch * 1000}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _AuthNotifier extends MultiAuthStateNotifier {
  _AuthNotifier() : super(const MultiAuthState());

  int signOutCount = 0;

  @override
  AuthState? get current => signOutCount == 0
      ? AuthState(account: _SessionAccount(), privateKey: '')
      : null;

  @override
  void signOut() => signOutCount++;
}

class _UnusedSettings implements SettingChangeNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedRustApi implements RustLibApi {
  @override
  Future<rust.RequestClient> crateApiHttpRegisterClient({
    required rust.ClientSettings settings,
  }) async => _UnusedRustClient();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedRustClient implements rust.RequestClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SessionAccount implements Account {
  @override
  String get sessionId => 'session';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
