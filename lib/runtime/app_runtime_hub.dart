import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../account/account_key_value.dart';
import '../account/account_server.dart';
import '../blaze/blaze.dart';
import '../db/database.dart';
import '../ui/provider/multi_auth_provider.dart';
import '../ui/provider/setting_provider.dart';
import '../utils/logger.dart';
import '../utils/platform.dart';
import '../utils/rivepod.dart';

typedef GetCurrentConversationId = String? Function();

enum AppRuntimePhase {
  idle,
  initializing,
  ready,
  failed,
}

class AppRuntimeState extends Equatable {
  const AppRuntimeState({
    required this.phase,
    required this.accountServer,
    this.connectedState,
    this.sessionKey,
    this.error,
    this.stackTrace,
  });

  const AppRuntimeState.idle()
    : this(
        phase: AppRuntimePhase.idle,
        accountServer: const AsyncValue.loading(),
      );

  final AppRuntimePhase phase;
  final AsyncValue<AccountServer> accountServer;
  final ConnectedState? connectedState;
  final String? sessionKey;
  final Object? error;
  final StackTrace? stackTrace;

  AppRuntimeState copyWith({
    AppRuntimePhase? phase,
    AsyncValue<AccountServer>? accountServer,
    ConnectedState? connectedState,
    String? sessionKey,
    Object? error = _unset,
    Object? stackTrace = _unset,
  }) => AppRuntimeState(
    phase: phase ?? this.phase,
    accountServer: accountServer ?? this.accountServer,
    connectedState: connectedState ?? this.connectedState,
    sessionKey: sessionKey ?? this.sessionKey,
    error: error == _unset ? this.error : error,
    stackTrace: stackTrace == _unset
        ? this.stackTrace
        : stackTrace as StackTrace?,
  );

  @override
  List<Object?> get props => [
    phase,
    accountServer,
    connectedState,
    sessionKey,
    error,
    stackTrace,
  ];
}

const _unset = Object();

class AppRuntimeArgs extends Equatable {
  const AppRuntimeArgs({
    required this.database,
    required this.userId,
    required this.sessionId,
    required this.identityNumber,
    required this.privateKey,
    required this.multiAuthNotifier,
    required this.settingChangeNotifier,
    required this.currentConversationId,
  });

  final Database? database;
  final String? userId;
  final String? sessionId;
  final String? identityNumber;
  final String? privateKey;
  final MultiAuthStateNotifier multiAuthNotifier;
  final SettingChangeNotifier settingChangeNotifier;
  final GetCurrentConversationId currentConversationId;

  @override
  List<Object?> get props => [
    database,
    userId,
    sessionId,
    identityNumber,
    privateKey,
    multiAuthNotifier,
    settingChangeNotifier,
    currentConversationId,
  ];
}

class AppRuntimeHub extends DistinctStateNotifier<AppRuntimeState> {
  AppRuntimeHub() : super(const AppRuntimeState.idle());

  final _authCoordinator = _AuthRuntimeCoordinator();
  final _connectionCoordinator = _ConnectionRuntimeCoordinator();
  final _syncCoordinator = _SyncRuntimeCoordinator();

  StreamSubscription<ConnectedState>? _connectionSubscription;
  String? _activeSessionKey;
  int _epoch = 0;
  bool _disposed = false;

  Future<void> updateArgs(AppRuntimeArgs args) async {
    if (_disposed) return;

    final snapshot = _authCoordinator.resolve(args);
    if (!snapshot.isReady) {
      await _teardownCurrentSession();
      state = const AppRuntimeState.idle();
      return;
    }

    if (_activeSessionKey == snapshot.sessionKey &&
        state.accountServer.hasValue) {
      return;
    }

    final localEpoch = ++_epoch;
    state = state.copyWith(
      phase: AppRuntimePhase.initializing,
      accountServer: const AsyncValue.loading(),
      sessionKey: snapshot.sessionKey,
      connectedState: ConnectedState.disconnected,
      error: null,
      stackTrace: null,
    );

    try {
      await _teardownCurrentSession();

      final accountServer = await _connectionCoordinator.connect(
        snapshot: snapshot,
        args: args,
      );

      if (_disposed || localEpoch != _epoch) {
        await accountServer.stop();
        return;
      }

      _activeSessionKey = snapshot.sessionKey;
      await _connectionSubscription?.cancel();
      _connectionSubscription = accountServer.connectedStateStream.listen((
        event,
      ) {
        state = state.copyWith(connectedState: event);
      });

      state = state.copyWith(
        phase: AppRuntimePhase.ready,
        accountServer: AsyncValue.data(accountServer),
      );

      unawaited(
        _syncCoordinator.onReady(
          accountServer: accountServer,
          snapshot: snapshot,
          args: args,
        ),
      );
    } catch (error, stackTrace) {
      if (_disposed || localEpoch != _epoch) return;
      state = state.copyWith(
        phase: AppRuntimePhase.failed,
        accountServer: AsyncValue.error(error, stackTrace),
        connectedState: ConnectedState.disconnected,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _teardownCurrentSession() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _syncCoordinator.reset();

    final current = state.accountServer.valueOrNull;
    if (current != null) {
      await _connectionCoordinator.disconnect(current);
    }
    _activeSessionKey = null;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _epoch += 1;
    await _teardownCurrentSession();
    _syncCoordinator.dispose();
    super.dispose();
  }
}

class _AuthRuntimeSnapshot {
  const _AuthRuntimeSnapshot({
    required this.userId,
    required this.sessionId,
    required this.identityNumber,
    required this.privateKey,
  });

  final String? userId;
  final String? sessionId;
  final String? identityNumber;
  final String? privateKey;

  bool get isReady =>
      userId != null &&
      sessionId != null &&
      identityNumber != null &&
      privateKey != null;

  String get sessionKey =>
      '${userId ?? ''}:${sessionId ?? ''}:${identityNumber ?? ''}';
}

class _AuthRuntimeCoordinator {
  _AuthRuntimeSnapshot resolve(AppRuntimeArgs args) => _AuthRuntimeSnapshot(
    userId: args.userId,
    sessionId: args.sessionId,
    identityNumber: args.identityNumber,
    privateKey: args.privateKey,
  );
}

class _ConnectionRuntimeCoordinator {
  Future<AccountServer> connect({
    required _AuthRuntimeSnapshot snapshot,
    required AppRuntimeArgs args,
  }) async {
    final database = args.database;
    if (!snapshot.isReady || database == null) {
      throw StateError('runtime args are not ready');
    }
    final accountServer = AccountServer(
      multiAuthNotifier: args.multiAuthNotifier,
      settingChangeNotifier: args.settingChangeNotifier,
      database: database,
      currentConversationId: args.currentConversationId,
    );
    await accountServer.initServer(
      snapshot.userId!,
      snapshot.sessionId!,
      snapshot.identityNumber!,
      snapshot.privateKey!,
    );
    return accountServer;
  }

  Future<void> disconnect(AccountServer accountServer) async {
    await accountServer.stop();
  }
}

class _SyncRuntimeCoordinator {
  String? _lastSyncedSessionKey;
  bool _disposed = false;

  Future<void> onReady({
    required AccountServer accountServer,
    required _AuthRuntimeSnapshot snapshot,
    required AppRuntimeArgs args,
  }) async {
    if (_disposed) return;
    if (_lastSyncedSessionKey == snapshot.sessionKey) return;
    _lastSyncedSessionKey = snapshot.sessionKey;

    try {
      await accountServer.refreshSelf();
      await accountServer.refreshFriends();
      await accountServer.refreshSticker();
      await accountServer.initCircles();
      await accountServer.checkMigration();
      await _checkDeviceConsistency(accountServer, args.multiAuthNotifier);
    } catch (error, stackTrace) {
      w('runtime sync bootstrap failed: $error, $stackTrace');
    }
  }

  Future<void> _checkDeviceConsistency(
    AccountServer accountServer,
    MultiAuthStateNotifier multiAuthNotifier,
  ) async {
    final currentDeviceId = await getDeviceId();
    if (currentDeviceId == 'unknown') return;

    final savedDeviceId = AccountKeyValue.instance.deviceId;
    if (savedDeviceId == null) {
      await AccountKeyValue.instance.setDeviceId(currentDeviceId);
      return;
    }

    if (savedDeviceId.toLowerCase() != currentDeviceId.toLowerCase()) {
      await accountServer.signOutAndClear();
      multiAuthNotifier.signOut();
    }
  }

  void reset() {
    _lastSyncedSessionKey = null;
  }

  void dispose() {
    _disposed = true;
    _lastSyncedSessionKey = null;
  }
}
