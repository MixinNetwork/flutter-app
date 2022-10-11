import 'package:drift/drift.dart';

class MillisDateConverter extends TypeConverter<DateTime, int> {
  const MillisDateConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}
