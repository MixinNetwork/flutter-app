import 'package:moor/moor.dart';

class MillisDateConverter extends TypeConverter<DateTime, int> {
  const MillisDateConverter();

  @override
  DateTime? mapToDart(int? fromDb) {
    if (fromDb == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);
  }

  @override
  int? mapToSql(DateTime? value) => value?.millisecondsSinceEpoch;
}
