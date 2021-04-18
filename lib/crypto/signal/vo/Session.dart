import 'package:moor/moor.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Session {
  Session(this.address, this.device, this.record, this.date);

  late int id = 0;
  late String address;
  late int device;
  late Uint8List record;
  late DateTime date;
}
