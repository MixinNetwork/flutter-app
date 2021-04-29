import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

class SimpleCubit<State> extends Cubit<State> {
  SimpleCubit(State state) : super(state);

  @override
  void emit(State state) => super.emit(state);
}

class OffsetCubit extends SimpleCubit<Offset?> {
  OffsetCubit(Offset? state) : super(state);
}
