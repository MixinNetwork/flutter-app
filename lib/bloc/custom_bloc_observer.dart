import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

class CustomBlocObserver extends BlocObserver {

  @override
  void onError(Bloc bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('Bloc Error: bloc: $bloc, error: $error, stackTrace: $stackTrace');
  }
}
