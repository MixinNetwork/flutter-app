import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;

import '../../../enum/property_group.dart';
import '../../../utils/db/db_key_value.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../../utils/hydrated_bloc.dart';
import '../../../utils/rivepod.dart';
import '../database_provider.dart';

part 'multi_auth_provider.g.dart';

@JsonSerializable()
class AuthState extends Equatable {
  const AuthState({
    required this.account,
    required this.privateKey,
  });

  factory AuthState.fromJson(Map<String, dynamic> map) =>
      _$AuthStateFromJson(map);

  @JsonKey(name: 'account')
  final Account account;
  @JsonKey(name: 'privateKey')
  final String privateKey;

  String get userId => account.userId;

  @override
  List<Object?> get props => [account, privateKey];

  Map<String, dynamic> toJson() => _$AuthStateToJson(this);
}

@JsonSerializable()
class MultiAuthState extends Equatable {
  MultiAuthState({
    this.auths = const [],
    String? activeUserId,
  }) : activeUserId = activeUserId ?? auths.lastOrNull?.userId;

  factory MultiAuthState.fromJson(Map<String, dynamic> map) =>
      _$MultiAuthStateFromJson(map);

  @JsonKey(name: 'auths')
  final List<AuthState> auths;

  /// activeUserId is the current activated account userId
  @JsonKey(name: 'activeUserId')
  final String? activeUserId;

  AuthState? get current {
    if (auths.isEmpty) {
      return null;
    }
    if (activeUserId != null) {
      return auths
          .firstWhereOrNull((element) => element.userId == activeUserId);
    }
    w('activeUserId is null');
    return auths.lastOrNull;
  }

  @override
  List<Object?> get props => [auths, activeUserId];

  Map<String, dynamic> toJson() => _$MultiAuthStateToJson(this);
}

class MultiAuthStateNotifier extends DistinctStateNotifier<MultiAuthState> {
  MultiAuthStateNotifier(this._multiAuthKeyValue) : super(MultiAuthState()) {
    _init().whenComplete(_initialized.complete);
  }

  final _initialized = Completer<void>();

  Future<void> get initialized => _initialized.future;

  Future<void> _init() async {
    await _multiAuthKeyValue.initialize;
    final auths = _multiAuthKeyValue.authList;
    var activeUserId = _multiAuthKeyValue.activeUserId;
    final migrated = _multiAuthKeyValue.authMigrated;
    unawaited(_multiAuthKeyValue.setAuthMigrated());
    if (auths.isEmpty && !migrated) {
      // check if old auths exist.
      final oldAuthState = _getLegacyMultiAuthState()?.auths.lastOrNull;
      if (oldAuthState != null) {
        i('migrate legacy auths');
        final signalDbMigrated = await _migrationLegacySignalDatabase(
            oldAuthState.account.identityNumber);
        if (signalDbMigrated) {
          auths.add(oldAuthState);
          activeUserId = oldAuthState.userId;
        } else {
          w('migration legacy signal database failed, ignore legacy auths.');
        }
      }
      _removeLegacyMultiAuthState();
      await _removeLegacySignalDatabase();
    }
    super.state = MultiAuthState(auths: auths, activeUserId: activeUserId);
  }

  final MultiAuthKeyValue _multiAuthKeyValue;

  AuthState? get current => state.current;

  void signIn(AuthState authState) {
    state = MultiAuthState(
      auths: [
        ...state.auths.where((element) => element.userId != authState.userId),
        authState,
      ],
      activeUserId: authState.userId,
    );
  }

  void updateAccount(Account account) {
    final index =
        state.auths.indexWhere((element) => element.userId == account.userId);
    if (index == -1) {
      i('update account, but ${account.userId} auth state not found.');
      return;
    }
    final auths = state.auths.toList();
    auths[index] = AuthState(
      account: account,
      privateKey: state.auths[index].privateKey,
    );
    state = MultiAuthState(auths: auths, activeUserId: state.activeUserId);
  }

  void signOut(String userId) {
    if (state.auths.isEmpty) return;
    final auths = state.auths.toList()
      ..removeWhere((element) => element.userId == userId);
    final activeUserId = state.activeUserId == userId
        ? auths.lastOrNull?.userId
        : state.activeUserId;
    state = MultiAuthState(auths: auths, activeUserId: activeUserId);
  }

  @override
  set state(MultiAuthState value) {
    _multiAuthKeyValue
      ..setAuthList(value.auths)
      ..setActiveUserId(value.activeUserId);
    super.state = value;
  }

  void active(String userId) {
    final exist = state.auths.any((element) => element.userId == userId);
    if (!exist) {
      e('failed to active, no account exist for id: $userId');
      return;
    }
    i('active account: $userId');
    state = MultiAuthState(
      auths: state.auths,
      activeUserId: userId,
    );
  }
}

const _kMultiAuthCubitKey = 'MultiAuthCubit';

MultiAuthState? _getLegacyMultiAuthState() {
  final oldJson = HydratedBloc.storage.read(_kMultiAuthCubitKey);
  if (oldJson == null) {
    return null;
  }
  return fromHydratedJson(oldJson, MultiAuthState.fromJson);
}

void _removeLegacyMultiAuthState() {
  HydratedBloc.storage.delete(_kMultiAuthCubitKey);
}

Future<void> _removeLegacySignalDatabase() async {
  final dbFolder = mixinDocumentsDirectory.path;
  const dbFiles = ['signal.db', 'signal.db-shm', 'signal.db-wal'];
  final files = dbFiles.map((e) => File(p.join(dbFolder, e)));
  for (final file in files) {
    try {
      if (file.existsSync()) {
        i('remove legacy signal database: ${file.path}');
        await file.delete();
      }
    } catch (error, stacktrace) {
      e('_removeLegacySignalDatabase ${file.path} error: $error, stacktrace: $stacktrace');
    }
  }
}

Future<bool> _migrationLegacySignalDatabase(String identityNumber) async {
  final dbFolder = p.join(mixinDocumentsDirectory.path, identityNumber);

  final dbFile = File(p.join(dbFolder, 'signal.db'));
  // migration only when new database file not exists.
  if (dbFile.existsSync()) {
    await _removeLegacySignalDatabase();
    return false;
  }

  final legacyDbFolder = mixinDocumentsDirectory.path;
  final legacyDbFile = File(p.join(legacyDbFolder, 'signal.db'));
  if (!legacyDbFile.existsSync()) {
    return false;
  }
  const dbFiles = ['signal.db', 'signal.db-shm', 'signal.db-wal'];
  final legacyFiles = dbFiles.map((e) => File(p.join(legacyDbFolder, e)));
  var hasError = false;
  for (final file in legacyFiles) {
    try {
      final newLocation = p.join(dbFolder, p.basename(file.path));
      // delete new location file if exists
      final newFile = File(newLocation);
      if (newFile.existsSync()) {
        await newFile.delete();
      }
      if (file.existsSync()) {
        await file.copy(newLocation);
      }
      i('migrate legacy signal database: ${file.path}');
    } catch (error, stacktrace) {
      e('_migrationLegacySignalDatabaseIfNecessary ${file.path} error: $error, stacktrace: $stacktrace');
      hasError = true;
    }
  }
  if (hasError) {
    // migration error. remove copied database file.
    for (final name in dbFiles) {
      final file = File(p.join(dbFolder, name));
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
  await _removeLegacySignalDatabase();
  return !hasError;
}

final multiAuthStateNotifierProvider =
    StateNotifierProvider<MultiAuthStateNotifier, MultiAuthState>((ref) {
  final multiAuthKeyValue = ref.watch(multiAuthKeyValueProvider);
  return MultiAuthStateNotifier(multiAuthKeyValue);
});

final authProvider =
    multiAuthStateNotifierProvider.select((value) => value.current);

final authAccountProvider = authProvider.select((value) => value?.account);

const _keyAuths = 'auths';
const _keyActiveUserId = 'active_user_id';
const _keyAuthMigrated = 'auth_migrated_from_hive';

final multiAuthKeyValueProvider = Provider<MultiAuthKeyValue>((ref) {
  final dao = ref.watch(appDatabaseProvider).appKeyValueDao;
  return MultiAuthKeyValue(dao: dao);
});

class MultiAuthKeyValue extends AppKeyValue {
  MultiAuthKeyValue({required super.dao}) : super(group: AppPropertyGroup.auth);

  List<AuthState> get authList {
    final json = get<List<Map<String, dynamic>>>(_keyAuths);
    if (json == null) {
      return [];
    }
    return json.map(AuthState.fromJson).toList();
  }

  String? get activeUserId => get(_keyActiveUserId);

  Future<void> setAuthList(List<AuthState> auths) =>
      set(_keyAuths, auths.map((e) => e.toJson()).toList());

  Future<void> setActiveUserId(String? userId) => set(_keyActiveUserId, userId);

  Future<void> setAuthMigrated() => set(_keyAuthMigrated, true);

  /// In old version, we use hive to store auths.
  /// from the vision of support multi account feature we use db key value to store auths.
  /// We only do one time migration from old version, because the signal database only
  /// migrate once.
  bool get authMigrated => get(_keyAuthMigrated) ?? false;
}
