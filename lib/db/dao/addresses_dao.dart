import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'addresses_dao.g.dart';

@UseDao(tables: [Addresses])
class AddressesDao extends DatabaseAccessor<MixinDatabase>
    with _$AddressesDaoMixin {
  AddressesDao(MixinDatabase db) : super(db);
}
