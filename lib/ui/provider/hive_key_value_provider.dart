import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../account/account_key_value.dart';
import '../../account/scam_warning_key_value.dart';
import '../../account/security_key_value.dart';
import '../../account/session_key_value.dart';
import '../../account/show_pin_message_key_value.dart';
import '../../crypto/crypto_key_value.dart';
import '../../crypto/privacy_key_value.dart';
import '../../utils/attachment/download_key_value.dart';
import '../../utils/hive_key_values.dart';
import 'account/multi_auth_provider.dart';

FutureProviderFamily<T, String>
    _createHiveKeyValueProvider<T extends HiveKeyValue>(
  T Function() create,
) =>
        FutureProviderFamily<T, String>(
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

final downloadKeyValueProvider =
    _createHiveKeyValueProvider(DownloadKeyValue.new);

final sessionKeyValueProvider =
    _createHiveKeyValueProvider(SessionKeyValue.new);

final currentSessionKeyValueProvider =
    FutureProvider.autoDispose<SessionKeyValue?>(
  (ref) async {
    final identityNumber =
        ref.watch(authAccountProvider.select((value) => value?.identityNumber));
    if (identityNumber == null) {
      return null;
    }
    return ref.watch(sessionKeyValueProvider(identityNumber).future);
  },
);

final privacyKeyValueProvider =
    _createHiveKeyValueProvider(PrivacyKeyValue.new);

final securityKeyValueProvider =
    _createHiveKeyValueProvider(SecurityKeyValue.new);

final showPinMessageKeyValueProvider =
    _createHiveKeyValueProvider(ShowPinMessageKeyValue.new);

final scamWarningKeyValueProvider =
    _createHiveKeyValueProvider(ScamWarningKeyValue.new);

class HiveKeyValues with EquatableMixin {
  HiveKeyValues({
    required this.accountKeyValue,
    required this.cryptoKeyValue,
    required this.sessionKeyValue,
    required this.privacyKeyValue,
    required this.downloadKeyValue,
    required this.securityKeyValue,
    required this.showPinMessageKeyValue,
    required this.scamWarningKeyValue,
  });

  final AccountKeyValue accountKeyValue;
  final CryptoKeyValue cryptoKeyValue;
  final SessionKeyValue sessionKeyValue;
  final PrivacyKeyValue privacyKeyValue;
  final DownloadKeyValue downloadKeyValue;
  final SecurityKeyValue securityKeyValue;
  final ShowPinMessageKeyValue showPinMessageKeyValue;
  final ScamWarningKeyValue scamWarningKeyValue;

  @override
  List<Object?> get props => [
        accountKeyValue,
        cryptoKeyValue,
        sessionKeyValue,
        privacyKeyValue,
        downloadKeyValue,
        securityKeyValue,
        showPinMessageKeyValue,
        scamWarningKeyValue,
      ];

  Future<void> clearAll() => Future.wait([
        accountKeyValue.clear(),
        cryptoKeyValue.clear(),
        sessionKeyValue.clear(),
        privacyKeyValue.clear(),
        downloadKeyValue.clear(),
        securityKeyValue.clear(),
        showPinMessageKeyValue.clear(),
        scamWarningKeyValue.clear(),
      ]);
}

final hiveKeyValueProvider =
    FutureProvider.autoDispose.family<HiveKeyValues, String>(
  (ref, identityNumber) async {
    assert(() {
      ref.onDispose(() {
        w('hiveKeyValueProvider: dispose $identityNumber');
      });
      return true;
    }());
    final accountKeyValue =
        await ref.watch(accountKeyValueProvider(identityNumber).future);
    final cryptoKeyValue =
        await ref.watch(cryptoKeyValueProvider(identityNumber).future);
    final sessionKeyValue =
        await ref.watch(sessionKeyValueProvider(identityNumber).future);
    final privacyKeyValue =
        await ref.watch(privacyKeyValueProvider(identityNumber).future);
    final downloadKeyValue =
        await ref.watch(downloadKeyValueProvider(identityNumber).future);
    final securityKeyValue =
        await ref.watch(securityKeyValueProvider(identityNumber).future);
    final showPinMessageKeyValue =
        await ref.watch(showPinMessageKeyValueProvider(identityNumber).future);
    final scamWarningKeyValue =
        await ref.watch(scamWarningKeyValueProvider(identityNumber).future);
    return HiveKeyValues(
      accountKeyValue: accountKeyValue,
      cryptoKeyValue: cryptoKeyValue,
      sessionKeyValue: sessionKeyValue,
      privacyKeyValue: privacyKeyValue,
      downloadKeyValue: downloadKeyValue,
      securityKeyValue: securityKeyValue,
      showPinMessageKeyValue: showPinMessageKeyValue,
      scamWarningKeyValue: scamWarningKeyValue,
    );
  },
);
