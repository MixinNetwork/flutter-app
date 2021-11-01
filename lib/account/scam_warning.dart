import 'package:rxdart/rxdart.dart';

import '../utils/hive_key_values.dart';

class ScamWarningKeyValue extends HiveKeyValue<DateTime?> {
  ScamWarningKeyValue._() : super(_hiveName);
  static const _hiveName = 'scam_warning_key_value';

  static ScamWarningKeyValue? _instance;

  static ScamWarningKeyValue get instance =>
      _instance ??= ScamWarningKeyValue._();

  bool isShow(String userId) {
    final dateTime = box.get(userId, defaultValue: null);
    if (dateTime == null) return true;
    return DateTime.now().isAfter(dateTime);
  }

  Future<void> dismiss(String userId) =>
      box.put(userId, DateTime.now().add(const Duration(days: 1)));

  Stream<bool> watch(String userId) => box
          .watch(key: userId)
          .map((event) => event.value)
          .where((event) => event is DateTime?)
          .cast<DateTime?>()
          .map((dateTime) {
        if (dateTime == null) return true;
        return DateTime.now().isAfter(dateTime);
      }).startWith(isShow(userId));
}
