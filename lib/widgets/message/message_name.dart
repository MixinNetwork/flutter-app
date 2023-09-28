import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/provider/setting_provider.dart';
import '../../utils/color_utils.dart';
import '../../utils/extension/extension.dart';
import '../high_light_text.dart';
import '../interactive_decorated_box.dart';
import '../user/user_dialog.dart';
import 'message_style.dart';

class MessageName extends ConsumerWidget {
  const MessageName({
    super.key,
    required this.userName,
    required this.userId,
    required this.userIdentityNumber,
  });

  final String userName;
  final String userId;
  final String userIdentityNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showIdentityNumber = ref.watch(
      settingProvider.select((value) => value.messageShowIdentityNumber),
    );
    Widget widget = HighlightText(
      userName,
      style: TextStyle(
        fontSize: context.messageStyle.secondaryFontSize,
        color: getNameColorById(userId),
      ),
    );
    if (showIdentityNumber && userIdentityNumber != '0') {
      widget = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          widget,
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '@$userIdentityNumber',
              style: TextStyle(
                fontSize: context.messageStyle.statusFontSize,
                color: context.theme.text.withOpacity(0.5),
              ),
            ),
          )
        ],
      );
    }
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
          child: widget,
        ),
      ),
    );
  }
}
