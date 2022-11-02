import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/resources.dart';
import '../../db/dao/asset_dao.dart';
import '../../utils/extension/extension.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../message/item/transfer/transfer_page.dart';

class MultisigsPaymentItem {
  const MultisigsPaymentItem({
    required this.senders,
    required this.receivers,
    required this.threshold,
    required this.asset,
    required this.amount,
    required this.state,
    required this.uri,
  });

  final List<String> senders;
  final List<String> receivers;
  final int threshold;
  final AssetItem asset;
  final String amount;

  final String state;

  final Uri uri;
}

class Multi2MultiItem extends MultisigsPaymentItem {
  Multi2MultiItem({
    required super.senders,
    required super.receivers,
    required super.threshold,
    required super.asset,
    required super.amount,
    required super.state,
    required this.action,
    required super.uri,
  });

  final String action;
}

Future<void> showMultisigsPaymentDialog(
  BuildContext context, {
  required MultisigsPaymentItem item,
}) async {
  await showMixinDialog(
    context: context,
    child: _PaymentDialog(item: item),
  );
}

extension _PaymentCodeResponseExt on MultisigsPaymentItem {
  bool get isDone => {'signed', 'unlocked', 'paid'}.contains(state);
}

class _PaymentDialog extends StatelessWidget {
  const _PaymentDialog({required this.item});

  final MultisigsPaymentItem item;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 12, top: 12),
                      child: MixinCloseButton(),
                    ),
                  ],
                ),
                _MultisigsPaymentBody(item: item),
              ],
            ),
          ),
        ],
      );
}

class _MultisigsPaymentBody extends HookWidget {
  const _MultisigsPaymentBody({
    required this.item,
  });

  final MultisigsPaymentItem item;

  @override
  Widget build(BuildContext context) {
    final asset = item.asset;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          (item is Multi2MultiItem &&
                  (item as Multi2MultiItem).action == 'cancel')
              ? context.l10n.revokeMultisigTransaction
              : context.l10n.multisigTransaction,
          style: TextStyle(
            fontSize: 18,
            color: context.theme.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${item.threshold}/${item.receivers.length}',
          style: TextStyle(
            fontSize: 14,
            color: context.theme.secondaryText,
          ),
        ),
        const SizedBox(height: 16),
        SymbolIconWithBorder(
          size: 48,
          symbolUrl: asset.iconUrl,
          chainUrl: asset.chainIconUrl,
          chainSize: 14,
          chainBorder: const BorderSide(color: Colors.white, width: 2),
        ),
        const SizedBox(height: 10),
        Text(
          '${item.amount.numberFormat()} ${asset.symbol}',
          style: TextStyle(
            fontSize: 16,
            color: context.theme.text,
          ),
        ),
        const SizedBox(height: 8),
        if (item.isDone) const _DoneLayout() else _QrCodeLayout(uri: item.uri),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _QrCodeLayout extends StatelessWidget {
  const _QrCodeLayout({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 40),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: SizedBox.square(
              dimension: 180,
              child: QrImage(
                data: uri.toString(),
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      );
}

class _DoneLayout extends StatelessWidget {
  const _DoneLayout();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.theme.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox.square(
                dimension: 60,
                child: SvgPicture.asset(
                  Resources.assetsImagesCheckedSvg,
                  color: context.theme.green,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.done,
            style: TextStyle(
              fontSize: 14,
              color: context.theme.secondaryText,
            ),
          ),
          const SizedBox(height: 40),
        ],
      );
}
