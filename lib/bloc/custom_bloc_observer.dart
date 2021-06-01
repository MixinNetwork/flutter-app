import 'package:bloc/bloc.dart';
import '../utils/logger.dart';

class CustomBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    w('Bloc Error: bloc: $bloc, error: $error, stackTrace: $stackTrace');
  }
}
