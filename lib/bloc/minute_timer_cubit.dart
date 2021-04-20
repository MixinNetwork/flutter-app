import 'dart:async';

import 'package:bloc/bloc.dart';

class MinuteTimerCubit extends Cubit<DateTime> {
  MinuteTimerCubit() : super(DateTime.now()) {
    timer = Timer.periodic(
      const Duration(minutes: 1),
      handleTimeout,
    );
  }

  late Timer timer;

  void handleTimeout(Timer timer) => emit(DateTime.now());

  @override
  Future<void> close() async {
    timer.cancel();
    await super.close();
  }
}
