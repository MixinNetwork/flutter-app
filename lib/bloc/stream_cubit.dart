import 'package:bloc/bloc.dart';
import 'subscribe_mixin.dart';

class StreamCubit<T> extends Cubit<T> with SubscribeMixin {
  StreamCubit(T state, Stream<T> stream) : super(state) {
    addSubscription(stream.distinct().listen(emit));
  }
}
