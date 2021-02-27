import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:intl/intl.dart';

class MessageDatetime extends StatelessWidget {
  const MessageDatetime({
    Key? key,
    required this.dateTime,
  }) : super(key: key);

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat.jm().format(dateTime),
      style: TextStyle(
        fontSize: 10,
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(131, 145, 158, 1),
          darkColor: const Color.fromRGBO(128, 131, 134, 1),
        ),
      ),
    );
  }
}

