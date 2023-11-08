import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../../account/account_server.dart';
import '../../../blaze/blaze.dart';
import '../../../db/database.dart';
import '../../../utils/rivepod.dart';
import '../../../utils/synchronized.dart';
import '../conversation_provider.dart';
import '../database_provider.dart';
import '../hive_key_value_provider.dart';
import '../setting_provider.dart';
import 'multi_auth_provider.dart';

typedef GetCurrentConversationId = String? Function();

class AccountServerOpener
    extends DistinctStateNotifier<AsyncValue<AccountServer>> {
  AccountServerOpener._(this.ref) : super(const AsyncValue.loading()) {
    _subscription = ref.listen<AsyncValue<_Args?>>(
      _argsProvider,
      (previous, next) {
        _onNewArgs(next.valueOrNull);
      },
    );
  }

  final AutoDisposeRef ref;
  ProviderSubscription? _subscription;

  final _lock = Lock();

  _Args? _previousArgs;

  Future<void> _onNewArgs(_Args? args) => _lock.synchronized(() async {
        if (_previousArgs == args) {
          return;
        }
        _previousArgs = args;
        if (args == null) {
          unawaited(state.valueOrNull?.stop());
          state = const AsyncValue.loading();
          return;
        }
        final before = state.valueOrNull;
        state = await AsyncValue.guard<AccountServer>(
          () => _openAccountServer(args),
        );
        unawaited(before?.stop());
      });

  Future<AccountServer> _openAccountServer(_Args args) async {
    d('create new account server');
    final accountServer = AccountServer(
      multiAuthNotifier: args.multiAuthChangeNotifier,
      settingChangeNotifier: args.settingChangeNotifier,
      database: args.database,
      currentConversationId: args.currentConversationId,
      ref: ref,
      hiveKeyValues: args.hiveKeyValues,
    );
    await accountServer.initServer(
      args.userId,
      args.sessionId,
      args.identityNumber,
      args.privateKey,
    );
    return accountServer;
  }

  @override
  void dispose() {
    _subscription?.close();
    state.valueOrNull?.stop();
    super.dispose();
  }
}

// create _Args for equatable
class _Args extends Equatable {
  const _Args({
    required this.database,
    required this.userId,
    required this.sessionId,
    required this.identityNumber,
    required this.privateKey,
    required this.multiAuthChangeNotifier,
    required this.settingChangeNotifier,
    required this.currentConversationId,
    required this.hiveKeyValues,
  });

  final Database database;
  final String userId;
  final String sessionId;
  final String identityNumber;
  final String privateKey;
  final MultiAuthStateNotifier multiAuthChangeNotifier;
  final SettingChangeNotifier settingChangeNotifier;
  final GetCurrentConversationId currentConversationId;
  final HiveKeyValues hiveKeyValues;

  @override
  List<Object?> get props => [
        database,
        userId,
        sessionId,
        identityNumber,
        privateKey,
        multiAuthChangeNotifier,
        settingChangeNotifier,
        currentConversationId,
        hiveKeyValues,
      ];
}

final Provider<GetCurrentConversationId> _currentConversationIdProvider =
    Provider<GetCurrentConversationId>(
  (ref) => () => ref.read(currentConversationIdProvider),
);

final _argsProvider = FutureProvider.autoDispose((ref) async {
  final database =
      ref.watch(databaseProvider.select((value) => value.valueOrNull));
  if (database == null) {
    return null;
  }
  final (userId, sessionId, identityNumber, privateKey) =
      ref.watch(authProvider.select((value) => (
            value?.account.userId,
            value?.account.sessionId,
            value?.account.identityNumber,
            value?.privateKey,
          )));
  if (userId == null ||
      sessionId == null ||
      identityNumber == null ||
      privateKey == null) {
    return null;
  }
  final multiAuthChangeNotifier =
      ref.watch(multiAuthStateNotifierProvider.notifier);
  final settingChangeNotifier = ref.watch(settingProvider);
  final currentConversationId = ref.read(_currentConversationIdProvider);
  final hiveKeyValues =
      await ref.watch(hiveKeyValueProvider(identityNumber).future);

  return _Args(
    database: database,
    userId: userId,
    sessionId: sessionId,
    identityNumber: identityNumber,
    privateKey: privateKey,
    multiAuthChangeNotifier: multiAuthChangeNotifier,
    settingChangeNotifier: settingChangeNotifier,
    currentConversationId: currentConversationId,
    hiveKeyValues: hiveKeyValues,
  );
});

final accountServerProvider = StateNotifierProvider.autoDispose<
    AccountServerOpener, AsyncValue<AccountServer>>(
  AccountServerOpener._,
);

final blazeConnectedStateProvider =
    StreamProvider.autoDispose<ConnectedState>((ref) {
  final accountServer =
      ref.watch(accountServerProvider.select((value) => value.valueOrNull));
  if (accountServer == null) {
    return const Stream.empty();
  }
  return accountServer.connectedStateStream;
});
