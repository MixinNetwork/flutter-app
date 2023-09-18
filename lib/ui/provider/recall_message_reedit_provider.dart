import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/rivepod.dart';

// Duration to keep reedit available after message recalled.
const _kReeditOutdatedDuration = Duration(minutes: 6);

class RecallMessageNotifier extends DistinctStateNotifier<Map<String, String>> {
  RecallMessageNotifier(this._onReEditStreamController) : super({});

  final StreamController<String> _onReEditStreamController;

  final Set<Timer> _timers = {};

  void _updateMessage(String messageId, String? content) {
    if (content == null) {
      state = {...state}..remove(messageId);
    } else {
      state = {
        ...state,
        messageId: content,
      };
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

  void onReedit(String content) => _onReEditStreamController.add(content);

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }
}

final _onReEditStreamControllerProvider =
    Provider((ref) => StreamController<String>.broadcast());

final onReEditStreamProvider = _onReEditStreamControllerProvider
    .select((value) => value.stream.where((event) => event.isNotEmpty));

final _recallMessageProvider =
    StateNotifierProvider<RecallMessageNotifier, Map<String, String>>(
  (ref) => RecallMessageNotifier(ref.watch(_onReEditStreamControllerProvider)),
);

final recalledTextProvider = Provider.family<String?, String>(
    (ref, messageId) => ref.watch(_recallMessageProvider)[messageId]);

final recallMessageNotifierProvider = _recallMessageProvider.notifier;
