import 'dart:async';

import '../../../bloc/simple_cubit.dart';
import '../../../bloc/subscribe_mixin.dart';

// Duration to keep reedit available after message recalled.
const _kReeditOutdatedDuration = Duration(minutes: 6);

class RecallMessageReeditCubit extends SimpleCubit<Map<String, String>>
    with SubscribeMixin {
  RecallMessageReeditCubit() : super(const {});

  final Map<String, String> _messages = {};

  final Set<Timer> _timers = {};

  final StreamController<String> _redditText = StreamController.broadcast();

  Stream<String> get onReeditStream => _redditText.stream;

  void _updateMessage(String messageId, String? content) {
    if (content == null) {
      _messages.remove(messageId);
    } else {
      _messages[messageId] = content;
    }
    emit(Map.from(_messages));
  }

  void onRecalled(String messageId, String content) {
    _updateMessage(messageId, content);
    Timer? timer;
    timer = Timer(_kReeditOutdatedDuration, () {
      _updateMessage(messageId, null);
      _timers.remove(timer);
    });
  }

  void onReedit(String content) {
    _redditText.add(content);
  }

  @override
  Future<void> close() async {
    await super.close();
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}
