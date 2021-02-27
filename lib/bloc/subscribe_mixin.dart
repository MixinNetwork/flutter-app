import 'dart:async';

import 'package:bloc/bloc.dart';

// mixin SubscribeCubitMixin<State> on Cubit<State> {
//   List<StreamSubscription> subscriptions = [];
//
//   void addSubscription(StreamSubscription streamSubscription) =>
//       subscriptions.add(streamSubscription);
//
//   @override
//   Future<void> close() async {
//     await Future.wait(subscriptions.map((e) => e?.cancel()));
//     subscriptions.clear();
//     await super.close();
//   }
// }
//
mixin SubscribeMixin<Event, State> on Bloc<Event, State> {
  List<StreamSubscription?> subscriptions = [];

  void addSubscription(StreamSubscription? streamSubscription) =>
      subscriptions.add(streamSubscription);

  @override
  Future<void> close() async {
    await Future.wait(subscriptions
        .where((element) => element != null)
        .map((e) => e!.cancel()));
    subscriptions.clear();
    await super.close();
  }
}
