import 'package:flutter_bloc/flutter_bloc.dart';

class SimpleCubit<State> extends Cubit<State> {
  SimpleCubit(State state) : super(state);

  @override
  void emit(State state) => super.emit(state);
}
