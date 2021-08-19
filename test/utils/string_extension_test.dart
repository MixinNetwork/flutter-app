import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('test escape sql', () {
    const keyword = r'()[]{}*+?.^$|\';
    expect(r'\(\)\[\]\{\}\*\+\?\.\^\$\|\\', keyword.escapeSql());
  });

  test('test join start', () {
    const s1 = 'hello520你好';
    const s2 = 'a1b2c3哈4de哈*# ~6f';

    expect('hello*520*你*好*', s1.joinStar());
    expect('a*1*b*2*c*3*哈*4*de*哈***#* ~*6*f*', s2.joinStar());
  });

  test('test join white space', () {
    const s1 = 'hello520你好';
    const s2 = 'a1b2c3哈4de哈*# ~6f';

    expect(s1.joinWhiteSpace(), 'hello 520 你 好');
    expect(s2.joinWhiteSpace(), 'a 1 b 2 c 3 哈 4 de 哈 * #  ~ 6 f');
  });
}
