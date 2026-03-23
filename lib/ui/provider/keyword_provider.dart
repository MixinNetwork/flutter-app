import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

class KeywordNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;

  void clear() => state = '';
}

final keywordProvider = NotifierProvider<KeywordNotifier, String>(
  KeywordNotifier.new,
);

final trimmedKeywordProvider = keywordProvider.select((value) => value.trim());

final hasKeywordProvider = trimmedKeywordProvider.select(
  (value) => value.isNotEmpty,
);

final debouncedKeywordProvider = StreamProvider.autoDispose<String>((ref) {
  final controller = BehaviorSubject<String>.seeded(
    ref.read(trimmedKeywordProvider),
  );

  ref.listen<String>(trimmedKeywordProvider, (previous, next) {
    controller.add(next);
  });

  ref.onDispose(controller.close);
  return controller.stream.distinct().debounceTime(
    const Duration(milliseconds: 150),
  );
});
