import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../account/account_key_value.dart';
import '../../../account/account_server.dart';
import '../../../blaze/blaze.dart';
import '../../../crypto/crypto_key_value.dart';
import '../../../db/database.dart';
import '../conversation_provider.dart';
import '../database_provider.dart';
import '../hive_key_value_provider.dart';
import '../setting_provider.dart';
import 'multi_auth_provider.dart';

typedef GetCurrentConversationId = String? Function();

class AccountServerOpener extends AutoDisposeStreamNotifier<AccountServer> {
  AccountServerOpener._();

  @override
  Stream<AccountServer> build() async* {
    final args = await ref.watch(_argsProvider.future);
    if (args == null) {
      return;
    }
    final accountServer = AccountServer(
      multiAuthNotifier: args.multiAuthChangeNotifier,
      settingChangeNotifier: args.settingChangeNotifier,
      database: args.database,
      currentConversationId: args.currentConversationId,
      ref: ref,
      accountKeyValue: args.accountKeyValue,
      cryptoKeyValue: args.cryptoKeyValue,
    );

    await accountServer.initServer(
      args.userId,
      args.sessionId,
      args.identityNumber,
      args.privateKey,
    );

    ref.onDispose(accountServer.stop);
    yield accountServer;
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
    required this.accountKeyValue,
    required this.cryptoKeyValue,
  });

  final Database database;
  final String userId;
  final String sessionId;
  final String identityNumber;
  final String privateKey;
  final MultiAuthStateNotifier multiAuthChangeNotifier;
  final SettingChangeNotifier settingChangeNotifier;
  final GetCurrentConversationId currentConversationId;
  final AccountKeyValue accountKeyValue;
  final CryptoKeyValue cryptoKeyValue;

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
        accountKeyValue,
        cryptoKeyValue,
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
  final accountKeyValue =
      await ref.watch(currentAccountKeyValueProvider.future);
  final cryptoKeyValue =
      await ref.watch(cryptoKeyValueProvider(identityNumber).future);
  if (accountKeyValue == null) {
    return null;
  }

  return _Args(
    database: database,
    userId: userId,
    sessionId: sessionId,
    identityNumber: identityNumber,
    privateKey: privateKey,
    multiAuthChangeNotifier: multiAuthChangeNotifier,
    settingChangeNotifier: settingChangeNotifier,
    currentConversationId: currentConversationId,
    accountKeyValue: accountKeyValue,
    cryptoKeyValue: cryptoKeyValue,
  );
});

final accountServerProvider =
    StreamNotifierProvider.autoDispose<AccountServerOpener, AccountServer>(
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
