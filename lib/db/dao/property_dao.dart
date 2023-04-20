import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'property_dao.g.dart';

@DriftAccessor(
  include: {'../moor/dao/property.drift'},
)
class PropertyDao extends DatabaseAccessor<MixinDatabase> {
  PropertyDao(super.attachedDatabase);
}
