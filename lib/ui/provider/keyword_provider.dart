import 'package:hooks_riverpod/hooks_riverpod.dart';

final keywordProvider = StateProvider<String>((ref) => '');
final trimmedKeywordProvider = keywordProvider.select((value) => value.trim());
final hasKeywordProvider = trimmedKeywordProvider.select(
  (value) => value.isNotEmpty,
);
