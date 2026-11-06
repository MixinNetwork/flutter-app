import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../account/deposit_entry.dart';
import '../../constants/icon_fonts.dart';
import '../../db/dao/token_dao.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/action_button.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialog.dart';
import '../../widgets/message/item/transfer/transfer_page.dart';
import '../../widgets/qr_code.dart';
import '../../widgets/toast.dart';
import '../provider/wallet_provider.dart';

Future<void> showDepositDialog(BuildContext context, String assetId) =>
    showMixinDialog(
      context: context,
      child: _DepositDialog(assetId: assetId),
    );

class _DepositDialog extends HookConsumerWidget {
  const _DepositDialog({required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(walletTokenProvider(assetId)).valueOrNull;
    final retry = useState(0);
    final client = context.accountServer.client;
    final chainId = token?.chainId;
    final entry = useMemoizedFuture<SafeDepositEntry?>(
      () async {
        if (chainId == null) return null;
        final entry = await fetchDepositEntry(
          client,
          chainId: chainId,
          assetId: assetId,
        );
        // An entry without a valid signature can be an address of someone
        // else, so it is an error, not an empty result.
        if (entry == null) throw ToastError.builder((c) => c.l10n.failed);
        return entry;
      },
      null,
      keys: [chainId, retry.value],
    );

    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.depositToken(token?.symbol ?? ''),
                    style: TextStyle(color: context.theme.text, fontSize: 16),
                  ),
                ),
                const MixinCloseButton(),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: switch ((token, entry)) {
                (_, AsyncSnapshot(:final error?)) => Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      ToastError.errorToString(context, error),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.theme.red),
                    ),
                    const SizedBox(height: 16),
                    MixinButton(
                      onTap: () => retry.value++,
                      child: Text(context.l10n.retry),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
                (final WalletTokenItem token, AsyncSnapshot(:final data?)) =>
                  _DepositEntry(token: token, entry: data),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositEntry extends StatelessWidget {
  const _DepositEntry({required this.token, required this.entry});

  final WalletTokenItem token;
  final SafeDepositEntry entry;

  @override
  Widget build(BuildContext context) {
    final tag = entry.tag;
    final hasTag = tag != null && tag.isNotEmpty;
    final noteStyle = TextStyle(
      color: context.theme.secondaryText,
      fontSize: 13,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SymbolIconWithBorder(
            symbolUrl: token.iconUrl,
            chainUrl: token.chainIconUrl,
            size: 40,
            chainSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _CopyableValue(label: context.l10n.address, value: entry.destination),
        if (hasTag) ...[
          const SizedBox(height: 16),
          _CopyableValue(label: context.l10n.memo, value: tag),
          const SizedBox(height: 8),
          Text(
            context.l10n.depositMemoNotice,
            style: TextStyle(color: context.theme.red, fontSize: 13),
          ),
        ],
        const SizedBox(height: 16),
        if (token.chainName != null) Text(token.chainName!, style: noteStyle),
        Text(
          context.l10n.depositDust(token.dust.numberFormat(), token.symbol),
          style: noteStyle,
        ),
        Text(
          context.l10n.depositConfirmation(
            token.confirmations,
            token.confirmations,
          ),
          style: noteStyle,
        ),
        Text(context.l10n.depositAttention, style: noteStyle),
      ],
    );
  }
}

class _CopyableValue extends StatelessWidget {
  const _CopyableValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: TextStyle(color: context.theme.secondaryText, fontSize: 13),
      ),
      const SizedBox(height: 8),
      Center(child: QrCode(data: value, dimension: 160)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: context.theme.text, fontSize: 14),
            ),
          ),
          ActionButton(
            size: 20,
            child: Icon(IconFonts.copy, size: 20, color: context.theme.icon),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) showToastSuccessful(context: context);
            },
          ),
        ],
      ),
    ],
  );
}
