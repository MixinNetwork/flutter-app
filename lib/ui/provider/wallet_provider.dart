import 'package:decimal/decimal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/dao/token_dao.dart';
import '../../db/database_event_bus.dart';
import '../../utils/extension/extension.dart';
import 'account_server_provider.dart';

final walletTokensProvider = StreamProvider.autoDispose
    .family<List<WalletTokenItem>, bool>((ref, hidden) {
      final database = ref.read(accountServerProvider).requireValue.database;
      return database.tokenDao
          .walletTokenItems(hidden: hidden)
          .watchWithStream(
            eventStreams: [DataBaseEventBus.instance.updateTokenStream],
            duration: kDefaultThrottleDuration,
          );
    });

final walletTokenProvider = StreamProvider.autoDispose
    .family<WalletTokenItem?, String>((ref, assetId) {
      final database = ref.read(accountServerProvider).requireValue.database;
      return database.tokenDao
          .walletTokenItem(assetId)
          .watchSingleOrNullWithStream(
            eventStreams: [
              DataBaseEventBus.instance.updateTokenStream.where(
                (event) => event.contains(assetId),
              ),
            ],
            duration: kDefaultThrottleDuration,
          );
    });

extension WalletTokenItemValue on WalletTokenItem {
  Decimal get usdValue => balance.asDecimalOrZero * priceUsd.asDecimalOrZero;
}
