import 'package:flutter/widgets.dart';

import '../utils/extension/extension.dart';

class Empty extends StatelessWidget {
  const Empty({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          text,
          style: TextStyle(
            color: context.theme.secondaryText,
          ),
        ),
      );
}
