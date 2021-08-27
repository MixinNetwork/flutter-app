import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../db/mixin_database.dart';
import '../../../ui/home/conversation_page.dart';
import '../../../utils/extension/extension.dart';
import '../../avatar_view/avatar_view.dart';
import '../../interacter_decorated_box.dart';
import '../../user/user_dialog.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class ContactMessageWidget extends StatelessWidget {
  const ContactMessageWidget({
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
        quoteMessageId: message.quoteId,
        quoteMessageContent: message.quoteContent,
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        outerTimeAndStatusWidget: MessageDatetimeAndStatus(
          showStatus: isCurrentUser,
          message: message,
        ),
        child: InteractableDecoratedBox(
          onTap: () => showUserDialog(
            context,
            message.sharedUserId,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarWidget(
                size: 40,
                avatarUrl: message.sharedUserAvatarUrl,
                userId: message.sharedUserId!,
                name: message.sharedUserFullName!,
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
                          message.sharedUserFullName!,
                          style: TextStyle(
                            color: context.theme.text,
                            fontSize: MessageItemWidget.primaryFontSize,
                          ),
                        ),
                      ),
                      VerifiedOrBotWidget(
                        verified: message.sharedUserIsVerified,
                        isBot: message.sharedUserAppId != null,
                      ),
                    ],
                  ),
                  Text(
                    message.sharedUserIdentityNumber!,
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
