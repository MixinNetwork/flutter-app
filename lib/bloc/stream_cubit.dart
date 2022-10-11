import 'package:bloc/bloc.dart';
import 'subscribe_mixin.dart';

class StreamCubit<T> extends Cubit<T> with SubscribeMixin {
  StreamCubit(super.state, Stream<T> stream) {
    addSubscription(stream.distinct().listen(emit));
  }
}
