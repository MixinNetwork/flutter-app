import 'package:moor/moor.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Session {
  late int id;
  late String address;
  late int device;
  late Uint8List record;
  late DateTime date;
}
