import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show SnapshotType, Ticker;

import '../../../../db/database_event_bus.dart';
import '../../../../db/mixin_database.dart' hide Offset;
import '../../../../ui/provider/account_server_provider.dart';
import '../../../../ui/provider/multi_auth_provider.dart';
import '../../../../ui/provider/transfer_provider.dart';
import '../../../../ui/provider/ui_context_providers.dart';
import '../../../../utils/extension/extension.dart';
import '../../../buttons.dart';
import '../../../dialog.dart';
import '../../../high_light_text.dart';
import 'safe_transfer_message.dart';
import 'transfer_page.dart';

Future<void> showSafeTransferDialog(BuildContext context, String snapshotId) =>
    showMixinDialog(
      context: context,
      child: _SafeTransferDialog(snapshotId: snapshotId),
    );

final _snapshotTypeProvider = Provider.family.autoDispose<String, SafeSnapshot>(
  (ref, snapshot) {
    if (snapshot.type == SnapshotType.pending) {
      return SnapshotType.pending;
    } else if (snapshot.withdrawal != null) {
      return SnapshotType.withdrawal;
    } else if (snapshot.deposit != null) {
      return SnapshotType.deposit;
    } else {
      return SnapshotType.transfer;
    }
  },
);

final _userProvider = StreamProvider.family.autoDispose<User?, String>((
  ref,
  userId,
) {
  final accountServer = ref.read(accountServerProvider).requireValue;

  final stream = accountServer.database.userDao
      .userById(userId)
      .watchSingleOrNullWithStream(
        eventStreams: [
          DataBaseEventBus.instance.watchUpdateUserStream([userId]),
        ],
        duration: kSlowThrottleDuration,
      );

  return stream.map((event) {
    if (event == null) accountServer.refreshUsers([userId]);
    return event;
  });
});

class _SafeTransferDialog extends HookConsumerWidget {
  const _SafeTransferDialog({required this.snapshotId});

  final String snapshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    useEffect(() {
      accountServer.updateFiats();
      return null;
    }, []);

    final snapshot = ref.watch(safeSnapshotProvider(snapshotId));
    useEffect(() {
      accountServer.updateSafeSnapshotById(snapshotId: snapshotId);
      return null;
    }, [snapshotId]);

    var token = const AsyncValue<Token?>.loading();
    final tokenId = snapshot.value?.assetId;
    if (tokenId != null) {
      token = ref.watch(tokenProvider(tokenId));
    }
    useEffect(() {
      if (tokenId == null) {
        return null;
      }
      accountServer.updateTokenById(assetId: tokenId);
      return null;
    }, [tokenId]);

    final snapshotValue = snapshot.value;
    final tokenValue = token.value;
    final chain = ref.watch(assetChainProvider(tokenValue?.chainId));

    if (snapshotValue == null) {
      return const SizedBox();
    }

    final isPositive = (double.tryParse(snapshotValue.amount) ?? 0) > 0;
    final type = ref.watch(_snapshotTypeProvider(snapshotValue));

    final fiatRate = ref.watch(_fiatRateProvider).unwrapPrevious().value;

    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Spacer(),
              Padding(
                padding: EdgeInsets.only(right: 12, top: 12),
                child: MixinCloseButton(),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SnapshotDetailHeader(
                    symbolIconUrl: tokenValue?.iconUrl ?? '',
                    chainIconUrl: chain.value?.iconUrl ?? '',
                    amount: snapshotValue.amount,
                    symbol: tokenValue?.symbol ?? '',
                    snapshotType: type,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: Builder(
                      builder: (context) {
                        if (tokenValue != null && fiatRate != null) {
                          return _ValuesDescription(
                            token: tokenValue,
                            fiatRate: fiatRate,
                            snapshot: snapshotValue,
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    color: theme.divider,
                    height: 10,
                  ),
                  _SafeTransactionDetailInfo(
                    snapshot: snapshotValue,
                    token: tokenValue,
                    isPositive: isPositive,
                    type: type,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _fiatRateProvider = StreamProvider.autoDispose<double?>((ref) {
  final accountServer = ref.watch(accountServerProvider).value;
  if (accountServer == null) {
    return const Stream.empty();
  }
  final db = accountServer.database.mixinDatabase;
  final fiatCurrency = ref.watch(
    authAccountProvider.select((value) => value?.fiatCurrency),
  );
  if (fiatCurrency == null) {
    return const Stream.empty();
  }
  return (db.select(db.fiats)..where(
        (tbl) => tbl.code.equals(fiatCurrency),
      ))
      .map((e) => e.rate)
      .watchSingle();
});

final _tickerProvider = FutureProvider.family
    .autoDispose<Ticker?, (String tokenId, String snapshotCreatedAt)>((
      ref,
      snapshot,
    ) async {
      final accountServer = ref.watch(accountServerProvider).value;
      if (accountServer == null) {
        return null;
      }
      final (tokenId, createdAt) = snapshot;
      final response = await accountServer.client.snapshotApi.getTicker(
        tokenId,
        offset: createdAt,
      );
      return response.data;
    });

class _ValuesDescription extends HookConsumerWidget {
  const _ValuesDescription({
    required this.token,
    required this.fiatRate,
    required this.snapshot,
  });

  final Token token;
  final SafeSnapshot snapshot;
  final double fiatRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final fiatCurrency = ref.watch(authAccountProvider)?.fiatCurrency;
    final ticker = ref
        .watch(_tickerProvider((snapshot.assetId, snapshot.createdAt)))
        .value;

    final String? thatTimeValue;

    final current =
        (snapshot.amount.asDecimal *
                token.priceUsd.asDecimal *
                fiatRate.asDecimal)
            .abs();
    final unitValue = currencyFormat(
      (current / snapshot.amount.asDecimal.abs()).toDouble(),
      fiatCurrency: fiatCurrency,
    );
    final symbol = token.symbol.overflow;
    final currentValue =
        '${l10n.valueNow(currencyFormat(current, fiatCurrency: fiatCurrency))}($unitValue/$symbol)';

    if (ticker == null) {
      thatTimeValue = null;
    } else if (ticker.priceUsd == '0') {
      thatTimeValue = l10n.valueThen(l10n.na);
    } else {
      final past =
          (snapshot.amount.asDecimal *
                  ticker.priceUsd.asDecimal *
                  fiatRate.asDecimal)
              .abs();
      final unitValue = currencyFormat(
        (past / snapshot.amount.asDecimal.abs()).toDouble(),
        fiatCurrency: fiatCurrency,
      );
      thatTimeValue =
          '${l10n.valueThen(currencyFormat(past, fiatCurrency: fiatCurrency))}($unitValue/$symbol)';
    }
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: theme.secondaryText,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomSelectableText(currentValue, enableInteractiveSelection: false),
          if (thatTimeValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CustomSelectableText(
                thatTimeValue,
                enableInteractiveSelection: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _SafeTransactionDetailInfo extends ConsumerWidget {
  const _SafeTransactionDetailInfo({
    required this.snapshot,
    required this.type,
    required this.token,
    required this.isPositive,
  });

  final SafeSnapshot snapshot;
  final String type;
  final Token? token;
  final bool isPositive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final createdAt = DateTime.parse(snapshot.createdAt).toLocal();
    final memo = parseSafeSnapshotMemo(snapshot.memo);
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (type == SnapshotType.pending) ...[
            TransactionInfoTile(
              title: Text(l10n.status),
              subtitle: CustomSelectableText(
                l10n.pendingConfirmation(
                  snapshot.confirmations ?? 0,
                  snapshot.confirmations ?? 0,
                  token?.confirmations ?? '',
                ),
              ),
            ),
            if (snapshot.deposit != null)
              TransactionInfoTile(
                title: Text(l10n.depositHash),
                subtitle: CustomSelectableText(snapshot.deposit!.depositHash),
              ),
          ] else ...[
            TransactionInfoTile(
              title: Text(l10n.transactionId),
              subtitle: CustomSelectableText(snapshot.snapshotId),
            ),
            TransactionInfoTile(
              title: Text(l10n.transactionHash),
              subtitle: CustomSelectableText(snapshot.transactionHash),
            ),
          ],
          if (type == SnapshotType.transfer) ...[
            TransactionInfoTile(
              title: Text(
                isPositive ? l10n.from : l10n.to,
              ),
              subtitle: CustomSelectableText(
                snapshot.opponentId.isNullOrBlank()
                    ? 'N/A'
                    : (ref
                              .watch(_userProvider(snapshot.opponentId))
                              .value
                              ?.fullName ??
                          ''),
              ),
            ),
            if (!memo.isNullOrBlank())
              TransactionInfoTile(
                title: Text(l10n.memo),
                subtitle: CustomSelectableText(memo),
              ),
          ] else if (type == SnapshotType.deposit &&
              snapshot.deposit != null) ...[
            TransactionInfoTile(
              title: Text(l10n.depositHash),
              subtitle: CustomSelectableText(
                snapshot.deposit?.depositHash ?? '',
              ),
            ),
          ] else if (type == SnapshotType.withdrawal) ...[
            TransactionInfoTile(
              title: Text(l10n.to),
              subtitle: CustomSelectableText(
                snapshot.withdrawal?.receiver ?? '',
              ),
            ),
            if ((snapshot.withdrawal?.withdrawalHash).isNullOrBlank())
              TransactionInfoTile(
                title: Text(l10n.withdrawalHash),
                subtitle: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.secondaryText,
                  ),
                ),
              )
            else
              TransactionInfoTile(
                title: Text(l10n.withdrawalHash),
                subtitle: CustomSelectableText(
                  snapshot.withdrawal?.withdrawalHash ?? '',
                ),
              ),
          ],
          TransactionInfoTile(
            title: Text(l10n.time),
            subtitle: CustomSelectableText(
              '${DateFormat.yMMMMd().format(createdAt)} '
              '${DateFormat.Hms().format(createdAt)}',
            ),
          ),
        ],
      ),
    );
  }
}
