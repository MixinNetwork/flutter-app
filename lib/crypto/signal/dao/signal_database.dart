import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/objectbox.g.dart';

class SignalDatabase {
  SignalDatabase(this.sessionId);

  final String sessionId;

  late Store _store;

  Future initStore() async {
    final dir = await getApplicationDocumentsDirectory();
    _store = Store(getObjectBoxModel(), directory: '${dir.path}/objectbox');
  }

  Store get store => _store;
}
