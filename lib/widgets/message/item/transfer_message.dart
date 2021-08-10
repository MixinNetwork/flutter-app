import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../constants/constants.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';
import '../../cache_image.dart';
import '../../interacter_decorated_box.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class TransferMessage extends StatelessWidget {
  const TransferMessage({
    Key? key,
    required this.message,
    required this.showNip,
    required this.isCurrentUser,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) => MessageBubble(
        messageId: message.messageId,
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        outerTimeAndStatusWidget: MessageDatetimeAndStatus(
          isCurrentUser: isCurrentUser,
          message: message,
        ),
        child: InteractableDecoratedBox(
          onTap: () => openUri(context,
              '${mixinProtocolUrls[MixinSchemeHost.snapshots]}/${message.snapshotId}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: CacheImage(
                  message.assetIcon!,
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
                          var amount = message.snapshotAmount;
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
                    message.assetSymbol!,
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
