import 'package:moor/moor.dart';

import '../signal_database.dart';

part 'identity_dao.g.dart';

@UseDao(tables: [Identities])
class IdentityDao extends DatabaseAccessor<SignalDatabase>
    with _$IdentityDaoMixin {
  IdentityDao(SignalDatabase db) : super(db);
}
