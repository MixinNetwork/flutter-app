import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../ui/home/bloc/conversation_cubit.dart';
import '../../utils/color_utils.dart';
import '../interacter_decorated_box.dart';

class MessageName extends StatelessWidget {
  const MessageName({
    Key? key,
    required this.userName,
    required this.userId,
    required this.isBot,
  }) : super(key: key);

  final String userName;
  final String userId;
  final bool isBot;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: InteractableDecoratedBox(
          onTap: () => context.read<ConversationCubit>().selectUser(
                userId,
                !isBot,
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
