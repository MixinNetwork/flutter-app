import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

class SimpleCubit<State> extends Cubit<State> {
  SimpleCubit(State state) : super(state);

  @override
  void emit(State state) => super.emit(state);
}

class IntCubit extends SimpleCubit<int> {
  IntCubit(int state) : super(state);
}

class BoolCubit extends SimpleCubit<bool> {
  BoolCubit(bool state) : super(state);
}

class DoubleCubit extends SimpleCubit<double> {
  DoubleCubit(double state) : super(state);
}

class OffsetCubit extends SimpleCubit<Offset>{
  OffsetCubit(Offset state) : super(state);
}
