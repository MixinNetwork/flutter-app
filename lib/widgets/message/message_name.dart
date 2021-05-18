import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../ui/home/bloc/conversation_cubit.dart';
import '../brightness_observer.dart';

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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.read<ConversationCubit>().selectUser(userId),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              bottom: 2,
            ),
            child: Text(
              userName,
              style: TextStyle(
                fontSize: 15,
                color: BrightnessData.themeOf(context).accent,
              ),
            ),
          ),
        ),
      );
}
