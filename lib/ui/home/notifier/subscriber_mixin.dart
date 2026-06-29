import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

mixin SubscriberMixin<State> on StateNotifier<State> {
  List<StreamSubscription?> subscriptions = [];

  void addSubscription(StreamSubscription? streamSubscription) =>
      subscriptions.add(streamSubscription);

  @override
  void dispose() {
    subscriptions
      ..forEach((element) => element?.cancel())
      ..clear();
    super.dispose();
  }
}
