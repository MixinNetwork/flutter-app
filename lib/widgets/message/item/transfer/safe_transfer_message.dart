import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../../../db/database_event_bus.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_style.dart';
import 'transfer_page.dart';

class SafeTransferMessage extends HookConsumerWidget {
  const SafeTransferMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetId = useMessageConverter(converter: (state) => state.assetId);

    var assetIcon = useMessageConverter(converter: (state) => state.assetIcon);
    final snapshotAmount =
    useMessageConverter(converter: (state) => state.snapshotAmount);
    final assetSymbol =
    useMessageConverter(converter: (state) => state.assetSymbol ?? '');


    final token = useMemoizedStream(() {
      if (assetId == null || assetIcon != null) {
        return Stream.value(null);
      }
      return context.database.assetDao
          .assetItem(assetId)
          .watchSingleOrNullWithStream(
        eventStreams: [
          DataBaseEventBus.instance.updateTokenStream
              .where((event) => event.contains(assetId))
        ],
        duration: kDefaultThrottleDuration,
      );
    }, keys: [assetId, assetIcon]).data;

    assetIcon = assetIcon ?? token?.iconUrl;

    useEffect(() {
      if (assetId != null && assetIcon != null) {
        return;
      }
      if (assetId == null) {
        e('${context.message.snapshotId}: assetId is null');
        return;
      }
      // context.accountServer.updateTokenById(assetId: assetId);
    }, [assetId]);

    return MessageBubble(
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
