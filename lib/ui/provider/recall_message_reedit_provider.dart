import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

// Duration to keep reedit available after message recalled.
const _kReeditOutdatedDuration = Duration(minutes: 6);

class RecallMessageNotifier extends Notifier<Map<String, String>> {
  final Set<Timer> _timers = {};

  @override
  Map<String, String> build() {
    ref.onDispose(() {
      for (final timer in _timers) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  void _updateMessage(String messageId, String? content) {
    if (content == null) {
      state = {...state}..remove(messageId);
    } else {
      state = {...state, messageId: content};
    }
  }

  void onRecalled(String messageId, String content) {
    _updateMessage(messageId, content);
    Timer? timer;
    timer = Timer(_kReeditOutdatedDuration, () {
      _updateMessage(messageId, null);
      _timers.remove(timer);
    });
    _timers.add(timer);
  }

  void onReedit(String content) =>
      ref.read(_onReEditStreamControllerProvider).add(content);
}

final _onReEditStreamControllerProvider = Provider(
  (ref) => StreamController<String>.broadcast(),
);

final onReEditStreamProvider = _onReEditStreamControllerProvider.select(
  (value) => value.stream.where((event) => event.isNotEmpty),
);

final _recallMessageProvider =
    NotifierProvider<RecallMessageNotifier, Map<String, String>>(
      RecallMessageNotifier.new,
    );

final recalledTextProvider = Provider.family<String?, String>(
  (ref, messageId) => ref.watch(_recallMessageProvider)[messageId],
);

final recallMessageNotifierProvider = _recallMessageProvider.notifier;
