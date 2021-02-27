import 'signal_database.dart';

class SignalDatabaseHelper {
  SignalDatabaseHelper._privateConstructor();

  static final SignalDatabaseHelper instance =
      SignalDatabaseHelper._privateConstructor();

  static SignalDatabase? _database;

  SignalDatabase get database {
    if (_database != null) return _database!;
    _database = SignalDatabase();
    return _database!;
  }
}
