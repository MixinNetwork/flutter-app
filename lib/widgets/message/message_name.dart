import 'package:flutter/widgets.dart';

import '../brightness_observer.dart';

class MessageName extends StatelessWidget {
  const MessageName({
    Key key,
    this.userName,
  }) : super(key: key);

  final String userName;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerLeft,
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
  );
}

