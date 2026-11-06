import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;
import 'package:rxdart/rxdart.dart';

import '../../db/dao/token_dao.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty.dart';
import '../../widgets/interactive_decorated_box.dart';
import '../../widgets/message/item/transfer/transfer_page.dart';
import '../../widgets/search_text_field.dart';
import '../../widgets/toast.dart';
import '../provider/wallet_provider.dart';
import 'deposit_dialog.dart';

/// Lets the user pick a token to deposit. Without a keyword it lists the
/// tokens that the user holds.
Future<void> showTokenSearchDialog(BuildContext context) =>
    showMixinDialog(context: context, child: const _TokenSearchDialog());

typedef _Result = ({String assetId, String name, String symbol, String icon});

class _TokenSearchDialog extends HookConsumerWidget {
  const _TokenSearchDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final textStream = useValueNotifierConvertSteam(controller);
    final keyword =
        useMemoizedStream(
          () => textStream
              .map((e) => e.text.trim())
              .distinct()
              .debounceTime(const Duration(milliseconds: 300)),
          keys: [textStream],
        ).data ??
        '';

    final client = context.accountServer.client;
    final found = useMemoizedFuture<List<sdk.Token>?>(
      () async => keyword.isEmpty
          ? null
          : (await client.assetApi.queryAsset(keyword)).data,
      null,
      keys: [keyword],
    ).data;
    final held = ref.watch(walletTokensProvider(false)).valueOrNull;
    final chains = useMemoizedStream(
      () => context.database.mixinDatabase
          .select(
            context.database.mixinDatabase.chains,
          )
          .watch(),
    ).data;
    final chainIcons = {
      for (final c in chains ?? <Chain>[]) c.chainId: c.iconUrl,
    };

    final results = keyword.isEmpty
        ? [
            for (final t in held ?? const <WalletTokenItem>[])
              (
                token: null,
                result: (
                  assetId: t.assetId,
                  name: t.name,
                  symbol: t.symbol,
                  icon: t.iconUrl,
                ),
                chainIcon: t.chainIconUrl,
              ),
          ]
        : [
            for (final t in found ?? const <sdk.Token>[])
              (
                token: t,
                result: (
                  assetId: t.assetId,
                  name: t.name,
                  symbol: t.symbol,
                  icon: t.iconUrl,
                ),
                chainIcon: chainIcons[t.chainId],
              ),
          ];

    Future<void> select(sdk.Token? token, String assetId) async {
      final accountServer = context.accountServer;
      final navigator = Navigator.of(context);
      final rootContext = navigator.context;
      if (token != null) {
        final ok = await runFutureWithToast(() async {
          await accountServer.database.tokenDao.insertSdkToken(token);
          if (!chainIcons.containsKey(token.chainId)) {
            final chain = (await client.assetApi.getChain(token.chainId)).data;
            await accountServer.database.chainDao.insertSdkChain(chain);
          }
        }());
        if (!ok) return;
      }
      navigator.pop();
      if (rootContext.mounted) await showDepositDialog(rootContext, assetId);
    }

    return SizedBox(
      width: 400,
      height: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.deposit,
                    style: TextStyle(color: context.theme.text, fontSize: 16),
                  ),
                ),
                const MixinCloseButton(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchTextField(
              controller: controller,
              hintText: context.l10n.searchPlaceholderAsset,
              autofocus: true,
              showClear: true,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: keyword.isNotEmpty && found != null && found.isEmpty
                ? Empty(text: context.l10n.noResults)
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final (:token, :result, :chainIcon) = results[index];
                      return _ResultItem(
                        result: result,
                        chainIcon: chainIcon,
                        onTap: () => select(token, result.assetId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  const _ResultItem({
    required this.result,
    required this.chainIcon,
    required this.onTap,
  });

  final _Result result;
  final String? chainIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox(
    hoveringDecoration: BoxDecoration(color: context.theme.listSelected),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SymbolIconWithBorder(
            symbolUrl: result.icon,
            chainUrl: chainIcon,
            size: 36,
            chainSize: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.symbol,
                  style: TextStyle(color: context.theme.text, fontSize: 15),
                ),
                Text(
                  result.name,
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
        ],
      ),
    ),
  );
}
