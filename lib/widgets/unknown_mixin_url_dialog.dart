import 'package:flutter/material.dart';

import '../utils/extension/extension.dart';
import 'dialog.dart';
import 'qr_code.dart';

Future<void> showUnknownMixinUrlDialog(
  BuildContext context,
  Uri uri,
) async =>
    showMixinDialog<void>(
      context: context,
      child: _UnknownMixinUri(uri: uri),
    );

class _UnknownMixinUri extends StatelessWidget {
  const _UnknownMixinUri({
    required this.uri,
  });

  final Uri uri;

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
                Text(
                  context.l10n.chatNotSupportUriOnPhone,
                  style: TextStyle(fontSize: 16, color: context.theme.text),
                ),
                const SizedBox(height: 36),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: QrCode(
                    dimension: 240,
                    data: uri.toString(),
                  ),
                ),
                const SizedBox(height: 36),
                MixinButton(
                  onTap: () => Navigator.pop(context, true),
                  child: Text(context.l10n.confirm),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      );
}
