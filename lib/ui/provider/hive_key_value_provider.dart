import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../account/account_key_value.dart';
import '../../crypto/crypto_key_value.dart';
import '../../utils/hive_key_values.dart';
import 'multi_auth_provider.dart';

AutoDisposeFutureProviderFamily<T, String>
    _createHiveKeyValueProvider<T extends HiveKeyValue>(
  T Function() create,
) =>
        AutoDisposeFutureProviderFamily<T, String>(
          (ref, identityNumber) async {
            final keyValue = create();
            ref.onDispose(keyValue.dispose);
            await keyValue.init(identityNumber);
            return keyValue;
          },
        );

final cryptoKeyValueProvider = _createHiveKeyValueProvider(CryptoKeyValue.new);

final accountKeyValueProvider =
    _createHiveKeyValueProvider(AccountKeyValue.new);

final currentAccountKeyValueProvider =
    FutureProvider.autoDispose<AccountKeyValue?>(
  (ref) async {
    final identityNumber =
        ref.watch(authAccountProvider.select((value) => value?.identityNumber));
    if (identityNumber == null) {
      return null;
    }
    return ref.watch(accountKeyValueProvider(identityNumber).future);
  },
);
