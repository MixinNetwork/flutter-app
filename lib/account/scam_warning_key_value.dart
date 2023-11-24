import 'package:rxdart/rxdart.dart';

import '../utils/hive_key_values.dart';

class ScamWarningKeyValue extends HiveKeyValue<DateTime?> {
  ScamWarningKeyValue() : super(_hiveName);
  static const _hiveName = 'scam_warning_key_value';

  bool _isShow(String userId) => box.get(userId, defaultValue: null).isShow;

  Future<void> dismiss(String userId) =>
      box.put(userId, DateTime.now().add(const Duration(days: 1)));

  Stream<bool> watch(String userId) => box
      .watch(key: userId)
      .map((event) => event.value)
      .where((event) => event is DateTime?)
      .cast<DateTime?>()
      .map((dateTime) => dateTime.isShow)
      .startWith(_isShow(userId));
}

extension _IsShowScamWarningExtension on DateTime? {
  bool get isShow {
    if (this == null) return true;
    return DateTime.now().isAfter(this!);
  }
}
