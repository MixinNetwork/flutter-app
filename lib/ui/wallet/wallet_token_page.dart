import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/dao/safe_snapshot_dao.dart';
import '../../db/database_event_bus.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty.dart';
import '../../widgets/interactive_decorated_box.dart';
import '../../widgets/message/item/transfer/safe_transfer_dialog.dart';
import '../../widgets/message/item/transfer/transfer_page.dart';
import '../provider/transfer_provider.dart';
import '../provider/wallet_provider.dart';
import 'deposit_dialog.dart';

const _kPageSize = 50;

class WalletTokenPage extends HookConsumerWidget {
  const WalletTokenPage({required this.assetId, super.key});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(walletTokenProvider(assetId)).valueOrNull;
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
      appBar: MixinAppBar(title: Text(token?.name ?? '')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: token == null
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        SymbolIconWithBorder(
                          symbolUrl: token.iconUrl,
                          chainUrl: token.chainIconUrl,
                          size: 56,
                          chainSize: 16,
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          '${token.balance.numberFormat()} ${token.symbol}',
                          style: TextStyle(
                            color: context.theme.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (fiatRate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.currencyFormat(
                              token.usdValue * fiatRate.asDecimal,
                            ),
                            style: TextStyle(
                              color: context.theme.secondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        MixinButton(
                          onTap: () => showDepositDialog(context, assetId),
                          child: Text(context.l10n.deposit),
                        ),
                      ],
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                context.l10n.transactions,
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (snapshots != null && snapshots.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Empty(text: context.l10n.noTransactions),
            )
          else
            SliverList.builder(
              itemCount: snapshots?.length ?? 0,
              itemBuilder: (context, index) {
                final items = snapshots!;
                if (index == items.length - 1 && items.length == limit.value) {
                  // The last row is visible, so load the next page.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => limit.value += _kPageSize,
                  );
                }
                return _SnapshotItem(snapshot: items[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _SnapshotItem extends StatelessWidget {
  const _SnapshotItem({required this.snapshot});

  final SafeSnapshotItem snapshot;

  @override
  Widget build(BuildContext context) {
    final isPositive = (double.tryParse(snapshot.amount) ?? 0) > 0;
    final title = snapshot.deposit != null
        ? context.l10n.deposit
        : snapshot.withdrawal != null
        ? context.l10n.withdrawal
        : snapshot.opponentFulName ?? context.l10n.transfer;
    return InteractiveDecoratedBox(
      hoveringDecoration: BoxDecoration(color: context.theme.listSelected),
      onTap: () => showSafeTransferDialog(context, snapshot.snapshotId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.theme.text, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateTime.parse(snapshot.createdAt).format,
                    style: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isPositive ? '+' : ''}${snapshot.amount.numberFormat()} '
              '${snapshot.assetSymbol ?? ''}',
              style: TextStyle(
                color: isPositive ? context.theme.green : context.theme.red,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
