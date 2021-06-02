import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../bloc/minute_timer_cubit.dart';
import '../../generated/l10n.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/hook.dart';
import '../brightness_observer.dart';

class MessageDayTime extends HookWidget {
  const MessageDayTime({
    Key? key,
    required this.dateTime,
  }) : super(key: key);

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final dateTimeString =
        useBlocStateConverter<MinuteTimerCubit, DateTime, String>(
      converter: (dateTime) {
        if (isSameDay(dateTime, this.dateTime)) {
          return Localization.of(context).today;
        }

        return convertStringTime(this.dateTime);
      },
      keys: [dateTime],
    );
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Container(
        height: 22,
        width: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: BrightnessData.themeOf(context).dateTime,
        ),
        alignment: Alignment.center,
        child: Text(dateTimeString),
      ),
    );
  }
}
