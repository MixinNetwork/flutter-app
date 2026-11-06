import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../db/dao/token_dao.dart';
import '../../db/database_event_bus.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty.dart';
import '../../widgets/interactive_decorated_box.dart';
import '../../widgets/menu.dart';
import '../../widgets/message/item/transfer/transfer_page.dart';
import '../provider/major_navigation_provider.dart';
import '../provider/slide_category_provider.dart';
import '../provider/transfer_provider.dart';
import '../provider/wallet_provider.dart';
import 'token_search_dialog.dart';

class WalletPage extends HookConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      slideCategoryStateProvider.select(
        (value) => value.type == SlideCategoryType.wallet,
      ),
    );
    final accountServer = context.accountServer;
    useEffect(() {
      if (!selected) return null;
      unawaited(accountServer.walletSync.syncBalances());
      unawaited(accountServer.walletSync.syncSnapshots());
      unawaited(accountServer.updateFiats());
      // A new snapshot changes the outputs of the user.
      final subscription = DataBaseEventBus.instance.updateSafeSnapshotStream
          .debounceTime(const Duration(seconds: 1))
          .listen((_) => accountServer.walletSync.syncBalances());
      return subscription.cancel;
    }, [selected]);

    final tokens = ref.watch(walletTokensProvider(false)).valueOrNull;
    final fiatRate = ref.watch(fiatRateProvider).valueOrNull;

    return ColoredBox(
      color: context.theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 64),
          _Header(tokens: tokens, fiatRate: fiatRate),
          Expanded(
            child: ListView.builder(
              itemCount: tokens?.length ?? 0,
              itemBuilder: (context, index) => _TokenItem(
                token: tokens![index],
                fiatRate: fiatRate,
              ),
            ),
          ),
          Divider(height: 1, color: context.theme.divider),
          InteractiveDecoratedBox(
            onTap: () => showMixinDialog(
              context: context,
              child: const _HiddenTokensDialog(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                context.l10n.hiddenAssets,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.theme.accent, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tokens, required this.fiatRate});

  final List<WalletTokenItem>? tokens;
  final double? fiatRate;

  @override
  Widget build(BuildContext context) {
    final fiatRate = this.fiatRate;
    final total = fiatRate == null
        ? null
        : (tokens ?? const <WalletTokenItem>[]).fold(
                Decimal.zero,
                (sum, token) => sum + token.usdValue,
              ) *
              fiatRate.asDecimal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.totalBalance,
            style: TextStyle(color: context.theme.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            total == null ? '' : context.currencyFormat(total),
            style: TextStyle(
              color: context.theme.text,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          MixinButton(
            onTap: () => showTokenSearchDialog(context),
            child: Text(context.l10n.deposit, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _TokenItem extends HookConsumerWidget {
  const _TokenItem({
    required this.token,
    required this.fiatRate,
    this.onOpened,
  });

  final WalletTokenItem token;
  final double? fiatRate;
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      majorNavigationProvider.select(
        (value) =>
            value.entries.lastOrNull ==
            MajorNavigationEntry(
              MajorNavigationDestination.walletTokenPage,
              arguments: token.assetId,
            ),
      ),
    );
    final fiatRate = this.fiatRate;
    return CustomContextMenuWidget(
      desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
      menuProvider: (_) => Menu(
        children: [
          MenuAction(
            title: token.hidden ? context.l10n.show : context.l10n.hide,
            callback: () => context.database.tokenDao
                .setHidden(token.kernelAssetId, hidden: !token.hidden)
                .then(
                  (_) => DataBaseEventBus.instance.updateToken([
                    token.assetId,
                  ]),
                ),
          ),
        ],
      ),
      child: InteractiveDecoratedBox(
        decoration: BoxDecoration(
          color: selected ? context.theme.listSelected : null,
        ),
        hoveringDecoration: BoxDecoration(color: context.theme.listSelected),
        onTap: () {
          ref
              .read(majorNavigationProvider.notifier)
              .openWalletToken(token.assetId);
          onOpened?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              SymbolIconWithBorder(
                symbolUrl: token.iconUrl,
                chainUrl: token.chainIconUrl,
                size: 40,
                chainSize: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      token.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.theme.text, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${token.balance.numberFormat()} ${token.symbol}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (fiatRate != null) ...[
                const SizedBox(width: 8),
                Text(
                  context.currencyFormat(token.usdValue * fiatRate.asDecimal),
                  style: TextStyle(color: context.theme.text, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenTokensDialog extends HookConsumerWidget {
  const _HiddenTokensDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(walletTokensProvider(true)).valueOrNull;
    final fiatRate = ref.watch(fiatRateProvider).valueOrNull;
    return SizedBox(
      width: 400,
      height: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.hiddenAssets,
                    style: TextStyle(color: context.theme.text, fontSize: 16),
                  ),
                ),
                const MixinCloseButton(),
              ],
            ),
          ),
          Expanded(
            child: tokens != null && tokens.isEmpty
                ? Empty(text: context.l10n.noHiddenAssets)
                : ListView.builder(
                    itemCount: tokens?.length ?? 0,
                    itemBuilder: (context, index) => _TokenItem(
                      token: tokens![index],
                      fiatRate: fiatRate,
                      onOpened: () => Navigator.pop(context),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
