import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import '../../bloc/minute_timer_cubit.dart';
import '../../utils/hook.dart';
import '../brightness_observer.dart';

class MessageDatetime extends HookWidget {
  const MessageDatetime({
    Key? key,
    required this.dateTime,
    this.color,
  }) : super(key: key);

  final DateTime dateTime;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = useBlocStateConverter<MinuteTimerCubit, DateTime, String>(
      converter: (_) => DateFormat.jm().format(dateTime),
    );
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: color ??
            BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(131, 145, 158, 1),
              darkColor: const Color.fromRGBO(128, 131, 134, 1),
            ),
      ),
    );
  }
}
