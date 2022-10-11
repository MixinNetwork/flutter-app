import 'package:flutter_bloc/flutter_bloc.dart';

class SimpleCubit<State> extends Cubit<State> {
  SimpleCubit(super.state);

  @override
  void emit(State state) => super.emit(state);
}
