import 'dart:async';

import 'package:bloc/bloc.dart';

mixin SubscribeMixin<State> on Cubit<State> {
  List<StreamSubscription> subscriptions = [];

  void addSubscription(StreamSubscription streamSubscription) =>
      subscriptions.add(streamSubscription);

  @override
  Future<void> close() async {
    await Future.wait(subscriptions.map((e) => e?.cancel()));
    subscriptions.clear();
    await super.close();
  }
}
