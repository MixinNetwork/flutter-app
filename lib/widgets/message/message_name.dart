import 'package:flutter/widgets.dart';

import '../../utils/color_utils.dart';
import '../high_light_text.dart';
import '../interactive_decorated_box.dart';
import '../user/user_dialog.dart';
import 'message_style.dart';

class MessageName extends StatelessWidget {
  const MessageName({
    super.key,
    required this.userName,
    required this.userId,
  });

  final String userName;
  final String userId;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: InteractiveDecoratedBox(
          onTap: () => showUserDialog(context, userId),
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              bottom: 2,
            ),
            child: HighlightText(
              userName,
              style: TextStyle(
                fontSize: context.messageStyle.secondaryFontSize,
                color: getNameColorById(userId),
              ),
            ),
          ),
        ),
      );
}
