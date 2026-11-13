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
import '../../widgets/app_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty.dart';
import '../../widgets/interactive_decorated_box.dart';
import '../../widgets/menu.dart';
import '../../widgets/message/item/transfer/transfer_page.dart';
import '../home/desktop_shell_layout.dart';
import '../provider/major_navigation_provider.dart';
import '../provider/slide_category_provider.dart';
import '../provider/transfer_provider.dart';
import '../provider/wallet_provider.dart';
import 'wallet_widgets.dart';

const _kTokenRowHeight = 70.0;

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

    _useOpenFirstToken(context, ref, selected: selected, tokens: tokens);

    // The first data shows as one whole frame. Only later changes animate.
    final ready =
        ref.watch(walletTokensProvider(false)).hasValue &&
        ref.watch(fiatRateProvider).hasValue;

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: MixinAppBar(title: Text(context.l10n.wallet)),
      body: !ready
          ? const SizedBox.shrink()
          : CustomScrollView(
              slivers: [
                SliverList.list(
                  children: [
                    _Overview(tokens: tokens, fiatRate: fiatRate),
                    AnimatedRows<WalletTokenItem>(
                      items: tokens ?? const [],
                      idOf: (token) => token.assetId,
                      rowHeight: _kTokenRowHeight,
                      itemBuilder: (context, token) =>
                          _TokenItem(token: token, fiatRate: fiatRate),
                    ),
                    InteractiveDecoratedBox(
                      hoveringDecoration: BoxDecoration(
                        color: context.theme.listSelected,
                      ),
                      onTap: () => showMixinDialog(
                        context: context,
                        child: const _HiddenTokensDialog(),
                      ),
                      child: SizedBox(
                        height: 56,
                        child: Center(
                          child: Text(
                            context.l10n.hiddenAssets,
                            style: TextStyle(
                              color: context.theme.accent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Opens the first token when the wallet shows no token, and again when the
/// open token leaves the list.
void _useOpenFirstToken(
  BuildContext context,
  WidgetRef ref, {
  required bool selected,
  required List<WalletTokenItem>? tokens,
}) {
  final routeMode = DesktopShellLayout.mainRouteModeOf(context);
  final opened = ref.watch(
    majorNavigationProvider.select((value) {
      final entry = value.entries.lastOrNull;
      return entry?.destination == MajorNavigationDestination.walletTokenPage
          ? entry!.arguments as String?
          : null;
    }),
  );
  final ids = tokens?.map((token) => token.assetId).toList();
  final previousIds = usePrevious(ids);
  useEffect(() {
    if (!selected || routeMode || ids == null || ids.isEmpty) return null;
    final left =
        opened != null &&
        (previousIds?.contains(opened) ?? false) &&
        !ids.contains(opened);
    if (opened != null && !left) return null;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          ref.read(majorNavigationProvider.notifier).openWalletToken(ids.first),
    );
    return null;
  }, [selected, routeMode, opened, ids?.join(',')]);
}

class _Overview extends StatelessWidget {
  const _Overview({required this.tokens, required this.fiatRate});

  final List<WalletTokenItem>? tokens;
  final double? fiatRate;

  @override
  Widget build(BuildContext context) {
    final tokens = this.tokens;
    final fiatRate = this.fiatRate;
    final total = tokens == null || fiatRate == null
        ? null
        : tokens.fold(Decimal.zero, (sum, token) => sum + token.usdValue) *
              fiatRate.asDecimal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.totalBalance,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          FadeText(
            total == null ? '-' : context.currencyFormat(total),
            style: TextStyle(
              color: context.theme.text,
              fontSize: 32,
              fontFamily: kWalletCondensedFont,
            ),
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
    final price = token.priceUsd.asDecimalOrZero;
    final hasPrice = price > Decimal.zero;
    final change = double.tryParse(token.changeUsd) ?? 0;
    final secondaryStyle = TextStyle(
      color: context.theme.secondaryText,
      fontSize: 12,
    );
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SymbolIconWithBorder(
                symbolUrl: token.iconUrl,
                chainUrl: token.chainIconUrl,
                size: 42,
                chainSize: 13,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                              fontSize: 20,
                              fontFamily: kWalletCondensedFont,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          token.symbol,
                          maxLines: 1,
                          style: TextStyle(
                            color: context.theme.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FadeText(
                      fiatRate == null
                          ? '≈ -'
                          : '≈ ${context.currencyFormat(token.usdValue * fiatRate.asDecimal)}',
                      style: secondaryStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (hasPrice)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FadeText(
                      formatChange(token.changeUsd),
                      alignment: AlignmentDirectional.centerEnd,
                      style: TextStyle(
                        color: change < 0
                            ? context.theme.red
                            : context.theme.green,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FadeText(
                      fiatRate == null
                          ? '-'
                          : context.currencyFormat(price * fiatRate.asDecimal),
                      alignment: AlignmentDirectional.centerEnd,
                      style: secondaryStyle,
                    ),
                  ],
                )
              else
                Text(context.l10n.na, style: secondaryStyle),
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
            child: AnimatedSwitcher(
              duration: kWalletMotion,
              child: tokens == null
                  ? const SizedBox.shrink()
                  : tokens.isEmpty
                  ? Empty(text: context.l10n.noHiddenAssets)
                  : SingleChildScrollView(
                      child: AnimatedRows<WalletTokenItem>(
                        items: tokens,
                        idOf: (token) => token.assetId,
                        rowHeight: _kTokenRowHeight,
                        itemBuilder: (context, token) => _TokenItem(
                          token: token,
                          fiatRate: fiatRate,
                          onOpened: () => Navigator.pop(context),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
