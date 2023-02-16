import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../utils/extension/extension.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_style.dart';
import 'transfer_page.dart';

class TransferMessage extends HookWidget {
  const TransferMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final assetIcon =
        useMessageConverter(converter: (state) => state.assetIcon);
    final chainIcon =
        useMessageConverter(converter: (state) => state.chainIcon);
    final snapshotAmount =
        useMessageConverter(converter: (state) => state.snapshotAmount);
    final assetSymbol =
        useMessageConverter(converter: (state) => state.assetSymbol ?? '');
    return MessageBubble(
      outerTimeAndStatusWidget:
          const MessageDatetimeAndStatus(hideStatus: true),
      child: InteractiveDecoratedBox(
        onTap: () {
          final snapshotId = context.message.snapshotId;
          if (snapshotId == null) return;
          showTransferDialog(context, snapshotId);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetIcon != null)
              SymbolIconWithBorder(
                symbolUrl: assetIcon,
                chainUrl: chainIcon,
                size: 40,
                chainSize: 12,
              ),
            if (assetIcon == null) const SizedBox(width: 40, height: 40),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Builder(builder: (context) {
                        if (snapshotAmount?.isEmpty ?? true) {
                          return const SizedBox();
                        }

                        return Text(
                          snapshotAmount!.numberFormat(),
                          style: TextStyle(
                            color: context.theme.text,
                            fontSize: context.messageStyle.secondaryFontSize,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                Text(
                  assetSymbol,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: context.messageStyle.tertiaryFontSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
