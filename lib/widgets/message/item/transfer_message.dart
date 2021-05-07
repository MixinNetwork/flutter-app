import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../db/mixin_database.dart';
import '../../brightness_observer.dart';
import '../../cache_image.dart';
import '../../interacter_decorated_box.dart';
import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

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
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        outerTimeAndStatusWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MessageDatetime(dateTime: message.createdAt),
            if (isCurrentUser) MessageStatusWidget(status: message.status),
          ],
        ),
        child: InteractableDecoratedBox(
          onTap: () {
            // TODO
          },
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

                            if (amount!.startsWith('-')) {
                              amount = numberFormat
                                  .format(int.parse(amount.substring(1)));
                            } else {
                              amount = numberFormat.format(int.parse(amount));
                            }
                          } catch (_) {}
                          return Text(
                            amount!,
                            style: TextStyle(
                              color: BrightnessData.themeOf(context).text,
                              fontSize: 14,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  Text(
                    message.assetSymbol!,
                    style: TextStyle(
                      color: BrightnessData.themeOf(context).secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
