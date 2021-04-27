import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/widgets/avatar_view/avatar_view.dart';
import 'package:flutter_app/widgets/message/item/quote_message.dart';
import 'package:provider/provider.dart';

import '../../brightness_observer.dart';
import '../../interacter_decorated_box.dart';
import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

class ContactMessage extends StatelessWidget {
  const ContactMessage({
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
        quoteMessage: QuoteMessage(
          id: message.quoteId,
          content: message.quoteContent,
        ),
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
          onTap: () => context
              .read<ConversationCubit>()
              .selectUser(message.sharedUserId!),
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
                            color: BrightnessData.themeOf(context).text,
                            fontSize: 14,
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
                    message.sharedUserIdentityNumber,
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
