import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/extension/extension.dart';
import '../../avatar_view/avatar_view.dart';
import '../../conversation/verified_or_bot_widget.dart';
import '../../interactive_decorated_box.dart';
import '../../user/user_dialog.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class ContactMessageWidget extends HookWidget {
  const ContactMessageWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sharedUserId =
        useMessageConverter(converter: (state) => state.sharedUserId);
    final sharedUserAvatarUrl =
        useMessageConverter(converter: (state) => state.sharedUserAvatarUrl);
    final sharedUserFullName =
        useMessageConverter(converter: (state) => state.sharedUserFullName);
    final sharedUserIsVerified =
        useMessageConverter(converter: (state) => state.sharedUserIsVerified);
    final sharedUserAppId =
        useMessageConverter(converter: (state) => state.sharedUserAppId);
    final sharedUserIdentityNumber = useMessageConverter(
        converter: (state) => state.sharedUserIdentityNumber ?? '');

    return MessageBubble(
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
      child: InteractiveDecoratedBox(
        onTap: () => showUserDialog(
          context,
          sharedUserId,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget(
              size: 40,
              avatarUrl: sharedUserAvatarUrl,
              userId: sharedUserId,
              name: sharedUserFullName,
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
                      child: Text(
                        sharedUserFullName ?? '',
                        style: TextStyle(
                          color: context.theme.text,
                          fontSize: MessageItemWidget.primaryFontSize,
                        ),
                      ),
                    ),
                    VerifiedOrBotWidget(
                      verified: sharedUserIsVerified,
                      isBot: sharedUserAppId != null,
                    ),
                  ],
                ),
                Text(
                  sharedUserIdentityNumber,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: MessageItemWidget.secondaryFontSize,
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
