import 'package:flutter/widgets.dart';

import '../../utils/color_utils.dart';
import '../interacter_decorated_box.dart';
import '../user/user_dialog.dart';
import 'message.dart';

class MessageName extends StatelessWidget {
  const MessageName({
    Key? key,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  final String userName;
  final String userId;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: InteractableDecoratedBox(
          onTap: () => showUserDialog(context, userId),
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              bottom: 2,
            ),
            child: Text(
              userName,
              style: TextStyle(
                fontSize: MessageItemWidget.secondaryFontSize,
                color: getNameColorById(userId),
              ),
            ),
          ),
        ),
      );
}
