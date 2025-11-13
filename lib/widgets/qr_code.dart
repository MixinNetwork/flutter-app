import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../utils/extension/extension.dart';
import 'dialog.dart';

class QrCode extends StatelessWidget {
  const QrCode({required this.data, super.key, this.image, this.dimension});

  final String data;
  final ImageProvider? image;
  final double? dimension;

  @override
  Widget build(BuildContext context) => Container(
    width: dimension,
    height: dimension,
    color: Colors.white,
    padding: const EdgeInsets.all(8),
    child: PrettyQrView.data(
      errorCorrectLevel: QrErrorCorrectLevel.Q,
      decoration: PrettyQrDecoration(
        image: image == null ? null : PrettyQrDecorationImage(image: image!),
      ),
      data: data,
    ),
  );
}

Future<void> showQrCodeDialog(BuildContext context, String data) async =>
    showMixinDialog<void>(
      context: context,
      child: _QrcodeDialog(data: data),
    );

class _QrcodeDialog extends StatelessWidget {
  const _QrcodeDialog({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      constraints: const BoxConstraints(minWidth: 320, minHeight: 210),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 36),
            QrCode(data: data, dimension: 240),
            const SizedBox(height: 20),
            MixinButton(
              onTap: () => Navigator.pop(context, true),
              child: Text(context.l10n.confirm),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
