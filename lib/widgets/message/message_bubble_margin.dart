import 'package:flutter/widgets.dart';

class MessageBubbleMargin extends StatelessWidget {
  const MessageBubbleMargin({
    Key? key,
    required this.child,
    required this.isCurrentUser,
  }) : super(key: key);

  final Widget child;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: isCurrentUser ? 65 : 16,
      right: !isCurrentUser ? 65 : 16,
      top: 2,
      bottom: 2,
    ),
    child: child,
  );
}

