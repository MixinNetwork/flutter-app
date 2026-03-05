import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../account/account_server.dart';
import '../../runtime/app_runtime_hub.dart';
import 'conversation_provider.dart';
import 'database_provider.dart';
import 'multi_auth_provider.dart';
import 'setting_provider.dart';

typedef GetCurrentConversationId = String? Function();

final Provider<GetCurrentConversationId> _currentConversationIdProvider =
    Provider<GetCurrentConversationId>(
      (ref) =>
          () => ref.read(currentConversationIdProvider),
    );

final _runtimeArgsProvider = Provider.autoDispose<AppRuntimeArgs>((ref) {
  final database = ref.watch(
    databaseProvider.select((value) => value.valueOrNull),
  );
  final authState = ref.watch(authProvider);
  final multiAuthNotifier = ref.read(multiAuthStateNotifierProvider.notifier);
  final settingChangeNotifier = ref.read(settingProvider);
  final currentConversationId = ref.read(_currentConversationIdProvider);

  return AppRuntimeArgs(
    database: database,
    userId: authState?.account.userId,
    sessionId: authState?.account.sessionId,
    identityNumber: authState?.account.identityNumber,
    privateKey: authState?.privateKey,
    multiAuthNotifier: multiAuthNotifier,
    settingChangeNotifier: settingChangeNotifier,
    currentConversationId: currentConversationId,
  );
});

final appRuntimeHubProvider =
    StateNotifierProvider.autoDispose<AppRuntimeHub, AppRuntimeState>((ref) {
      ref.keepAlive();
      final hub = AppRuntimeHub();
      ref.listen<AppRuntimeArgs>(_runtimeArgsProvider, (previous, next) {
        unawaited(hub.updateArgs(next));
      }, fireImmediately: true);
      return hub;
    });

final accountServerProvider = Provider.autoDispose<AsyncValue<AccountServer>>(
  (ref) =>
      ref.watch(appRuntimeHubProvider.select((value) => value.accountServer)),
);
