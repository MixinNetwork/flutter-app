import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/extension/extension.dart';
import 'dialog.dart';

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
                  context.l10n.uriCheckOnPhone,
                  style: TextStyle(fontSize: 16, color: context.theme.text),
                ),
                const SizedBox(height: 36),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: SizedBox.square(
                    dimension: 240,
                    child: QrImage(
                      data: uri.toString(),
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                    ),
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
