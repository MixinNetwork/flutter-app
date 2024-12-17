import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../ui/provider/setting_provider.dart';
import '../../utils/color_utils.dart';
import '../../utils/extension/extension.dart';
import '../conversation/badges_widget.dart';
import '../high_light_text.dart';
import '../interactive_decorated_box.dart';
import '../user/user_dialog.dart';
import 'message_style.dart';

class MessageName extends ConsumerWidget {
  const MessageName({
    required this.userName,
    required this.userId,
    required this.userIdentityNumber,
    required this.verified,
    required this.isBot,
    required this.membership,
    super.key,
  });

  final String userName;
  final String userId;
  final String userIdentityNumber;
  final bool? verified;
  final bool isBot;
  final Membership? membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showIdentityNumber = ref.watch(
      settingProvider.select((value) => value.messageShowIdentityNumber),
    );
    final children = <Widget>[
      CustomText(
        userName,
        style: TextStyle(
          fontSize: context.messageStyle.secondaryFontSize,
          color: getNameColorById(userId),
        ),
      )
    ];

    if (showIdentityNumber && userIdentityNumber != '0') {
      children
        ..add(const SizedBox(width: 2))
        ..add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '@$userIdentityNumber',
            style: TextStyle(
              fontSize: context.messageStyle.statusFontSize,
              color: context.theme.text.withValues(alpha: 0.5),
            ),
          ),
        ));
    }

    children.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: BadgesWidget(
          verified: verified,
          isBot: isBot,
          membership: membership,
        ),
      ),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: InteractiveDecoratedBox(
        onTap: () => showUserDialog(context, userId),
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 10,
            bottom: 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
