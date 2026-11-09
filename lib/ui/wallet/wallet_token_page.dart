import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../db/dao/safe_snapshot_dao.dart';
import '../../db/dao/token_dao.dart';
import '../../db/database_event_bus.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/interactive_decorated_box.dart';
import '../../widgets/message/item/transfer/safe_transfer_dialog.dart';
import '../../widgets/message/item/transfer/transfer_page.dart';
import '../provider/transfer_provider.dart';
import '../provider/wallet_provider.dart';
import 'wallet_widgets.dart';

const _kPageSize = 50;

class WalletTokenPage extends HookConsumerWidget {
  const WalletTokenPage({required this.assetId, super.key});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The list already holds the token, so the page draws it on the first
    // frame instead of waiting for its own query.
    final token =
        ref.watch(walletTokenProvider(assetId)).valueOrNull ??
        ref
            .watch(walletTokensProvider(false))
            .valueOrNull
            ?.where((token) => token.assetId == assetId)
            .firstOrNull;
    final fiatRate = ref.watch(fiatRateProvider).valueOrNull;

    final limit = useState(_kPageSize);
    final snapshots = useMemoizedStream(
      () => context.database.safeSnapshotDao
          .snapshotItemsByAssetId(assetId, limit: limit.value)
          .watchWithStream(
            eventStreams: [DataBaseEventBus.instance.updateSafeSnapshotStream],
            duration: kDefaultThrottleDuration,
          ),
      keys: [assetId, limit.value],
    ).data;

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(token?.name ?? '', maxLines: 1),
            if (token?.chainName case final chainName?)
              Text(
                chainName,
                maxLines: 1,
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
      // Cards keep a readable width and stay centered in a wide window.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.max<double>(10, (constraints.maxWidth - 600) / 2);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, 10, side, 0),
                sliver: SliverToBoxAdapter(
                  child: token == null
                      ? const SizedBox.shrink()
                      : _BalanceCard(token: token, fiatRate: fiatRate),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side, vertical: 10),
                sliver: DecoratedSliver(
                  decoration: BoxDecoration(
                    color: context.theme.settingCellBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 5),
                          child: Text(
                            context.l10n.transactions,
                            style: TextStyle(
                              color: context.theme.text,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      SliverAnimatedOpacity(
                        duration: kWalletMotion,
                        curve: kWalletCurve,
                        opacity: snapshots == null ? 0 : 1,
                        sliver: snapshots != null && snapshots.isEmpty
                            ? SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 60,
                                  ),
                                  child: Text(
                                    context.l10n.noTransactions.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.theme.secondaryText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            : SliverList.builder(
                                itemCount: snapshots?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final items = snapshots!;
                                  if (index == items.length - 1 &&
                                      items.length == limit.value) {
                                    // The last row is visible, so load the next
                                    // page.
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                          (_) => limit.value += _kPageSize,
                                        );
                                  }
                                  return _SnapshotItem(
                                    snapshot: items[index],
                                    token: token,
                                  );
                                },
                              ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.token, required this.fiatRate});

  final WalletTokenItem token;
  final double? fiatRate;

  @override
  Widget build(BuildContext context) {
    final fiatRate = this.fiatRate;
    return WalletCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: FadeText(
                              token.balance.numberFormat(),
                              style: TextStyle(
                                color: context.theme.text,
                                fontSize: 32,
                                fontFamily: kWalletCondensedFont,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            token.symbol,
                            style: TextStyle(
                              color: context.theme.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FadeText(
                        fiatRate == null
                            ? '≈ -'
                            : '≈ ${context.currencyFormat(token.usdValue * fiatRate.asDecimal)}',
                        style: TextStyle(
                          color: context.theme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SymbolIconWithBorder(
                  symbolUrl: token.iconUrl,
                  chainUrl: token.chainIconUrl,
                  size: 48,
                  chainSize: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotItem extends StatelessWidget {
  const _SnapshotItem({required this.snapshot, required this.token});

  final SafeSnapshotItem snapshot;
  final WalletTokenItem? token;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(snapshot.amount) ?? 0;
    final deposit = snapshot.deposit;
    final withdrawal = snapshot.withdrawal;
    final pending =
        (deposit != null &&
            (snapshot.confirmations ?? 0) <
                (snapshot.assetConfirmations ?? 0)) ||
        (withdrawal != null && withdrawal.withdrawalHash.isEmpty);
    final title = deposit != null
        ? context.l10n.deposit
        : withdrawal != null
        ? context.l10n.withdrawal
        : snapshot.opponentFulName ?? context.l10n.transfer;
    final token = this.token;
    return InteractiveDecoratedBox(
      hoveringDecoration: BoxDecoration(color: context.theme.listSelected),
      onTap: () => showSafeTransferDialog(context, snapshot.snapshotId),
      child: SizedBox(
        height: 62,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (deposit == null &&
                  withdrawal == null &&
                  Uuid.isValidUUID(fromString: snapshot.opponentId))
                AvatarWidget(
                  size: 42,
                  avatarUrl: snapshot.avatarUrl,
                  userId: snapshot.opponentId,
                  name: snapshot.opponentFulName,
                )
              else if (token != null)
                SymbolIconWithBorder(
                  symbolUrl: token.iconUrl,
                  chainUrl: token.chainIconUrl,
                  size: 42,
                  chainSize: 13,
                )
              else
                const SizedBox.square(dimension: 42),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.theme.text, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateTime.parse(snapshot.createdAt).format,
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${amount > 0 ? '+' : ''}${snapshot.amount.numberFormat()}',
                style: TextStyle(
                  color: pending
                      ? context.theme.secondaryText
                      : amount < 0
                      ? context.theme.red
                      : context.theme.green,
                  fontSize: 20,
                  fontFamily: kWalletCondensedFont,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                snapshot.assetSymbol ?? '',
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
