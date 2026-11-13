import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show SnapshotType, Ticker;

import '../../../../db/database_event_bus.dart';
import '../../../../db/mixin_database.dart' hide Offset;
import '../../../../ui/provider/account_server_provider.dart';
import '../../../../ui/provider/transfer_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../buttons.dart';
import '../../../dialog.dart';
import '../../../high_light_text.dart';
import 'safe_transfer_message.dart';
import 'transfer_page.dart';

Future<void> showSafeTransferDialog(
  BuildContext context,
  String snapshotId,
) async {
  // Reads the local data before the dialog shows, so that its first frame is
  // whole and only the data from the network comes in later.
  final container = context.providerContainer;
  final subscriptions = <ProviderSubscription<Object?>>[];
  Future<void> preload() async {
    final snapshotProvider = safeSnapshotProvider(snapshotId);
    subscriptions.add(container.listen(snapshotProvider, (_, _) {}));
    final snapshot = await container.read(snapshotProvider.future);
    if (snapshot != null) {
      final token = tokenProvider(snapshot.assetId);
      subscriptions
        ..add(container.listen(token, (_, _) {}))
        ..add(container.listen(fiatRateProvider, (_, _) {}));
      final (tokenValue, _) = await (
        container.read(token.future),
        container.read(fiatRateProvider.future),
      ).wait;
      if (tokenValue != null) {
        final chain = assetChainProvider(tokenValue.chainId);
        subscriptions.add(container.listen(chain, (_, _) {}));
        await container.read(chain.future);
      }
    }
  }

  try {
    try {
      // The dialog reads what is still missing itself.
      await preload().timeout(const Duration(milliseconds: 300));
    } on Object catch (_) {}
    if (!context.mounted) return;
    await showMixinDialog(
      context: context,
      child: _SafeTransferDialog(snapshotId: snapshotId),
    );
  } finally {
    for (final subscription in subscriptions) {
      subscription.close();
    }
  }
}

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
    useEffect(() {
      context.accountServer.updateFiats();
    }, []);

    final snapshot = ref.watch(safeSnapshotProvider(snapshotId));
    useEffect(() {
      context.accountServer.updateSafeSnapshotById(snapshotId: snapshotId);
    }, [snapshotId]);

    var token = const AsyncValue<Token?>.loading();
    final tokenId = snapshot.valueOrNull?.assetId;
    if (tokenId != null) {
      token = ref.watch(tokenProvider(tokenId));
    }
    useEffect(() {
      if (tokenId == null) {
        return;
      }
      context.accountServer.updateTokenById(assetId: tokenId);
    }, [tokenId]);

    final snapshotValue = snapshot.valueOrNull;
    final tokenValue = token.valueOrNull;
    final chain = ref.watch(assetChainProvider(tokenValue?.chainId));

    if (snapshotValue == null) {
      return const SizedBox();
    }

    final isPositive = (double.tryParse(snapshotValue.amount) ?? 0) > 0;
    final type = ref.watch(_snapshotTypeProvider(snapshotValue));

    final fiatRate = ref.watch(fiatRateProvider).unwrapPrevious().valueOrNull;

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
                    chainIconUrl: chain.valueOrNull?.iconUrl ?? '',
                    amount: snapshotValue.amount,
                    symbol: tokenValue?.symbol ?? '',
                    snapshotType: type,
                  ),
                  AnimatedSize(
                    duration: Durations.short3,
                    curve: Easing.standard,
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
                  Container(color: context.theme.divider, height: 10),
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

final _tickerProvider = FutureProvider.family
    .autoDispose<Ticker?, (String tokenId, String snapshotCreatedAt)>((
      ref,
      snapshot,
    ) async {
      final accountServer = ref.watch(accountServerProvider).valueOrNull;
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
    final ticker = ref
        .watch(_tickerProvider((snapshot.assetId, snapshot.createdAt)))
        .valueOrNull;

    final String? thatTimeValue;

    final current =
        (snapshot.amount.asDecimal *
                token.priceUsd.asDecimal *
                fiatRate.asDecimal)
            .abs();
    final unitValue = context.currencyFormat(
      (current / snapshot.amount.asDecimal.abs()).toDouble(),
    );
    final symbol = token.symbol.overflow;
    final currentValue =
        '${context.l10n.valueNow(context.currencyFormat(current))}($unitValue/$symbol)';

    if (ticker == null) {
      thatTimeValue = null;
    } else if (ticker.priceUsd == '0') {
      thatTimeValue = context.l10n.valueThen(context.l10n.na);
    } else {
      final past =
          (snapshot.amount.asDecimal *
                  ticker.priceUsd.asDecimal *
                  fiatRate.asDecimal)
              .abs();
      final unitValue = context.currencyFormat(
        (past / snapshot.amount.asDecimal.abs()).toDouble(),
      );
      thatTimeValue =
          '${context.l10n.valueThen(context.currencyFormat(past))}($unitValue/$symbol)';
    }
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: context.theme.secondaryText,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomSelectableText(currentValue, enableInteractiveSelection: false),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            // Holds the line while the price is loading, so that nothing
            // moves when it comes in.
            child: thatTimeValue == null
                ? Visibility.maintain(
                    visible: false,
                    child: CustomSelectableText(
                      context.l10n.valueThen(context.l10n.na),
                      enableInteractiveSelection: false,
                    ),
                  )
                : _FadeIn(
                    child: CustomSelectableText(
                      thatTimeValue,
                      enableInteractiveSelection: false,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Fades in when it first shows. It does not grow, because it is a line under
/// a line of the same kind.
class _FadeIn extends HookWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: Durations.short3);
    useEffect(() {
      controller.forward();
      return null;
    }, const []);
    final animation = useMemoized(
      () => CurvedAnimation(
        parent: controller,
        curve: Easing.emphasizedDecelerate,
      ),
    );
    return FadeTransition(opacity: animation, child: child);
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
              title: Text(context.l10n.status),
              subtitle: CustomSelectableText(
                context.l10n.pendingConfirmation(
                  snapshot.confirmations ?? 0,
                  snapshot.confirmations ?? 0,
                  token?.confirmations ?? '',
                ),
              ),
            ),
            if (snapshot.deposit != null)
              TransactionInfoTile(
                title: Text(context.l10n.depositHash),
                subtitle: CustomSelectableText(snapshot.deposit!.depositHash),
              ),
          ] else ...[
            TransactionInfoTile(
              title: Text(context.l10n.transactionId),
              subtitle: CustomSelectableText(snapshot.snapshotId),
            ),
            TransactionInfoTile(
              title: Text(context.l10n.transactionHash),
              subtitle: CustomSelectableText(snapshot.transactionHash),
            ),
          ],
          if (type == SnapshotType.transfer) ...[
            TransactionInfoTile(
              title: Text(isPositive ? context.l10n.from : context.l10n.to),
              subtitle: CustomSelectableText(
                snapshot.opponentId.isNullOrBlank()
                    ? 'N/A'
                    : (ref
                              .watch(_userProvider(snapshot.opponentId))
                              .valueOrNull
                              ?.fullName ??
                          ''),
              ),
            ),
            if (!memo.isNullOrBlank())
              TransactionInfoTile(
                title: Text(context.l10n.memo),
                subtitle: CustomSelectableText(memo),
              ),
          ] else if (type == SnapshotType.deposit &&
              snapshot.deposit != null) ...[
            TransactionInfoTile(
              title: Text(context.l10n.depositHash),
              subtitle: CustomSelectableText(
                snapshot.deposit?.depositHash ?? '',
              ),
            ),
          ] else if (type == SnapshotType.withdrawal) ...[
            TransactionInfoTile(
              title: Text(context.l10n.to),
              subtitle: CustomSelectableText(
                snapshot.withdrawal?.receiver ?? '',
              ),
            ),
            if ((snapshot.withdrawal?.withdrawalHash).isNullOrBlank())
              TransactionInfoTile(
                title: Text(context.l10n.withdrawalHash),
                subtitle: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.theme.secondaryText,
                  ),
                ),
              )
            else
              TransactionInfoTile(
                title: Text(context.l10n.withdrawalHash),
                subtitle: CustomSelectableText(
                  snapshot.withdrawal?.withdrawalHash ?? '',
                ),
              ),
          ],
          TransactionInfoTile(
            title: Text(context.l10n.time),
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
