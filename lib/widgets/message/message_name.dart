import 'package:flutter/widgets.dart';

import '../../ui/home/bloc/conversation_cubit.dart';
import '../../utils/color_utils.dart';
import '../interacter_decorated_box.dart';

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
          onTap: () => ConversationCubit.selectUser(
            context,
            userId,
          ),
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              bottom: 2,
            ),
            child: Text(
              userName,
              style: TextStyle(
                fontSize: 15,
                color: getNameColorById(userId),
              ),
            ),
          ),
        ),
      );
}
