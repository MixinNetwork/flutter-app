import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/utils/string_extension.dart';
import 'package:ulid/ulid.dart';

void main() {
  test('test nameUuid', () {
    const s1 = 'Hello Mixin';
    const s2 = 'Hello Flutter';
    final uuid1 = s1.nameUuid();
    final uuid11 = s1.nameUuid();
    final uuid2 = s2.nameUuid();

    Ulid.parse(uuid1);
    Ulid.parse(uuid11);
    Ulid.parse(uuid2);

    assert(uuid1 == uuid11);
    assert(uuid1 != uuid2);
  });
}
