import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../account/account_server.dart';
import '../../db/database.dart';
import '../../utils/logger.dart';
import 'database_provider.dart';
import 'multi_auth_provider.dart';
import 'setting_provider.dart';

class AccountServerOpener extends StateNotifier<AsyncValue<AccountServer>> {
  AccountServerOpener() : super(const AsyncValue.loading());

  AccountServerOpener.open({
    required this.multiAuthChangeNotifier,
    required this.settingChangeNotifier,
    required this.database,
    required this.userId,
    required this.sessionId,
    required this.identityNumber,
    required this.privateKey,
  }) : super(const AsyncValue.loading()) {
    _init();
  }

  late final MultiAuthChangeNotifier multiAuthChangeNotifier;
  late final SettingChangeNotifier settingChangeNotifier;
  late final Database database;

  late final String userId;
  late final String sessionId;
  late final String identityNumber;
  late final String privateKey;

  Future<void> _init() async {
    final accountServer = AccountServer(
      multiAuthChangeNotifier,
      settingChangeNotifier,
      database: database,
    );

    await accountServer.initServer(
      userId,
      sessionId,
      identityNumber,
      privateKey,
    );

    state = AsyncValue.data(accountServer);
  }

  @override
  Future<void> dispose() async {
    await state.valueOrNull?.stop();
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
  });

  final Database? database;
  final String? userId;
  final String? sessionId;
  final String? identityNumber;
  final String? privateKey;
  final MultiAuthChangeNotifier multiAuthChangeNotifier;
  final SettingChangeNotifier settingChangeNotifier;

  @override
  List<Object?> get props => [
        database,
        userId,
        sessionId,
        identityNumber,
        privateKey,
        multiAuthChangeNotifier,
        settingChangeNotifier,
      ];
}

final _argsProvider = Provider.autoDispose((ref) {
  final database =
      ref.watch(databaseProvider.select((value) => value.valueOrNull));
  final (userId, sessionId, identityNumber, privateKey) =
      ref.watch(authProvider.select((value) => (
            value?.account.userId,
            value?.account.sessionId,
            value?.account.identityNumber,
            value?.privateKey,
          )));
  final multiAuthChangeNotifier = ref.watch(multiAuthNotifierProvider);
  final settingChangeNotifier = ref.watch(settingProvider);
  return _Args(
    database: database,
    userId: userId,
    sessionId: sessionId,
    identityNumber: identityNumber,
    privateKey: privateKey,
    multiAuthChangeNotifier: multiAuthChangeNotifier,
    settingChangeNotifier: settingChangeNotifier,
  );
});

final accountServerProvider = StateNotifierProvider.autoDispose<
    AccountServerOpener, AsyncValue<AccountServer>>((ref) {
  final args = ref.watch(_argsProvider);

  if (args.database == null) return AccountServerOpener();
  if (args.userId == null ||
      args.sessionId == null ||
      args.identityNumber == null ||
      args.privateKey == null) {
    w('[accountServerProvider] Account not ready');
    return AccountServerOpener();
  }

  return AccountServerOpener.open(
    multiAuthChangeNotifier: args.multiAuthChangeNotifier,
    settingChangeNotifier: args.settingChangeNotifier,
    database: args.database!,
    userId: args.userId!,
    sessionId: args.sessionId!,
    identityNumber: args.identityNumber!,
    privateKey: args.privateKey!,
  );
});
