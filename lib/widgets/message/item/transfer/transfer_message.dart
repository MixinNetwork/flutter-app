import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../../../db/database_event_bus.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_style.dart';
import 'transfer_page.dart';

class TransferMessage extends HookConsumerWidget {
  const TransferMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetId = useMessageConverter(converter: (state) => state.assetId);

    var assetIcon = useMessageConverter(converter: (state) => state.assetIcon);
    var chainIcon = useMessageConverter(converter: (state) => state.chainIcon);
    final snapshotAmount =
        useMessageConverter(converter: (state) => state.snapshotAmount);
    final assetSymbol =
        useMessageConverter(converter: (state) => state.assetSymbol ?? '');

    final assetItem = useMemoizedStream(() {
      if (assetId == null || assetIcon != null) {
        return Stream.value(null);
      }
      return context.database.assetDao
          .assetItem(assetId)
          .watchSingleOrNullWithStream(
        eventStreams: [
          DataBaseEventBus.instance.updateAssetStream
              .where((event) => event.contains(assetId))
        ],
        duration: kDefaultThrottleDuration,
      );
    }, keys: [assetId, assetIcon]).data;

    assetIcon = assetIcon ?? assetItem?.iconUrl;
    chainIcon = chainIcon ?? assetItem?.chainIconUrl;

    useEffect(() {
      if (chainIcon != null && assetId != null) return;
      if (assetId == null) {
        e('${context.message.snapshotId}: assetId is null');
        return;
      }
      context.accountServer.updateAssetById(assetId: assetId);
    }, [chainIcon, assetId]);

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
                            fontSize: ref
                                .watch(messageStyleProvider)
                                .secondaryFontSize,
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
                    fontSize: ref.watch(messageStyleProvider).tertiaryFontSize,
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
