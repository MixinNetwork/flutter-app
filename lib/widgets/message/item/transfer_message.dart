import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../constants/constants.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';
import '../../cache_image.dart';
import '../../interactive_decorated_box.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class TransferMessage extends StatelessWidget {
  const TransferMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final assetIcon =
        useMessageConverter(converter: (state) => state.assetIcon ?? '');
    final snapshotAmount =
        useMessageConverter(converter: (state) => state.snapshotAmount);
    final assetSymbol =
        useMessageConverter(converter: (state) => state.assetSymbol ?? '');
    return MessageBubble(
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
      child: InteractiveDecoratedBox(
        onTap: () => openUri(context,
            '${mixinProtocolUrls[MixinSchemeHost.snapshots]}/${context.message.snapshotId}'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: CacheImage(
                assetIcon,
                width: 40,
                height: 40,
              ),
            ),
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
                        var amount = snapshotAmount;
                        if (amount?.isEmpty ?? true) return const SizedBox();

                        try {
                          final numberFormat = NumberFormat.decimalPattern(
                              Intl.getCurrentLocale());
                          amount = numberFormat.format(int.parse(amount!));
                        } catch (_) {}
                        return Text(
                          amount!,
                          style: TextStyle(
                            color: context.theme.text,
                            fontSize: MessageItemWidget.secondaryFontSize,
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
                    fontSize: MessageItemWidget.tertiaryFontSize,
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
