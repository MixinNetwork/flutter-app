import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
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
import 'wallet_widgets.dart';

Future<void> showDepositDialog(BuildContext context, String assetId) =>
    showMixinDialog(
      context: context,
      backgroundColor: context.theme.background,
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

    final data = entry.data;
    final error = entry.error;
    final tag = data?.tag;
    final hasTag = tag != null && tag.isNotEmpty;

    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.depositToken(token?.symbol ?? ''),
                    style: TextStyle(
                      color: context.theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const MixinCloseButton(),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  if (hasTag) ...[
                    _EntryCard(
                      label: context.l10n.memo,
                      value: tag,
                      warning: context.l10n.depositMemoNotice,
                      token: token,
                      error: null,
                      onRetry: null,
                    ),
                  ],
                  _EntryCard(
                    label: context.l10n.address,
                    value: data?.destination,
                    token: token,
                    error: error,
                    onRetry: () => retry.value++,
                  ),
                  if (token != null) _Notes(token: token),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The card of one deposit value, laid out as on iOS: the label and the
/// value, the QR code with the token icon, and the copy action. Its size
/// does not change when the value loads.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.label,
    required this.value,
    required this.token,
    required this.error,
    required this.onRetry,
    this.warning,
  });

  final String label;
  final String? value;
  final String? warning;
  final WalletTokenItem? token;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final error = this.error;
    final token = this.token;
    return WalletCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            // A long address, such as MobileCoin's, grows the card in one
            // motion instead of a jump.
            AnimatedSize(
              duration: kWalletMotion,
              curve: kWalletCurve,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: kWalletMotion,
                layoutBuilder: (current, previous) =>
                    Stack(children: [...previous, ?current]),
                child: SelectionArea(
                  key: ValueKey(value),
                  child: Text.rich(
                    TextSpan(
                      text: value ?? '',
                      children: [
                        if (value != null)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 4,
                              ),
                              // Keeps the button out of the selection and
                              // its text cursor.
                              child: SelectionContainer.disabled(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Tooltip(
                                    message: context.l10n.copy,
                                    child: ActionButton(
                                      size: 18,
                                      padding: const EdgeInsets.all(2),
                                      onTap: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: value),
                                        );
                                        if (context.mounted) {
                                          showToastSuccessful(context: context);
                                        }
                                      },
                                      child: Icon(
                                        IconFonts.copy,
                                        size: 18,
                                        color: context.theme.icon,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      color: context.theme.text,
                      // As on iOS, a longer value uses a smaller size.
                      fontSize: switch (value?.length ?? 0) {
                        > 120 => 12,
                        > 100 => 14,
                        _ => 16,
                      },
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
            if (warning != null) ...[
              const SizedBox(height: 8),
              Text(
                warning!,
                style: TextStyle(color: context.theme.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            Center(
              child: SizedBox.square(
                dimension: 200,
                child: AnimatedSwitcher(
                  duration: kWalletMotion,
                  switchInCurve: kWalletCurve,
                  child: value != null
                      ? Stack(
                          key: ValueKey(value),
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
                              child: QrCode(data: value, dimension: 200),
                            ),
                            if (token != null)
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: SymbolIconWithBorder(
                                  symbolUrl: token.iconUrl,
                                  chainUrl: token.chainIconUrl,
                                  size: 40,
                                  chainSize: 12,
                                ),
                              ),
                          ],
                        )
                      : error != null
                      ? Column(
                          key: const ValueKey('error'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ToastError.errorToString(context, error),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.theme.red,
                                fontSize: 14,
                              ),
                            ),
                            if (!_isDepositSuspended(error)) ...[
                              const SizedBox(height: 12),
                              MixinButton(
                                onTap: onRetry,
                                child: Text(context.l10n.retry),
                              ),
                            ],
                          ],
                        )
                      : const Center(
                          key: ValueKey('loading'),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.token});

  final WalletTokenItem token;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: context.theme.secondaryText,
      fontSize: 13,
      height: 1.4,
    );
    return WalletCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            if (token.chainName != null) Text(token.chainName!, style: style),
            Text(
              context.l10n.depositDust(token.dust.numberFormat(), token.symbol),
              style: style,
            ),
            Text(
              context.l10n.depositConfirmation(
                token.confirmations,
                token.confirmations,
              ),
              style: style,
            ),
            Text(context.l10n.depositAttention, style: style),
          ],
        ),
      ),
    );
  }
}

/// The server answers 202 with code 10104 while it cannot give a deposit
/// address for the chain. iOS shows the deposit as suspended, and a retry
/// gets the same answer.
bool _isDepositSuspended(Object error) =>
    error is MixinApiError && (error.error as MixinError?)?.code == 10104;
