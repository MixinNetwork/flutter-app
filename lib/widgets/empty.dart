import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';

class Empty extends StatelessWidget {
  const Empty({Key key, @required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          text,
          style: TextStyle(
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(184, 189, 199, 1),
              darkColor: const Color.fromRGBO(184, 189, 199, 1),
            ),
          ),
        ),
      );
}
