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
    const s3 = '😀😃😄😁😆😅😂🤣😊😇';

    expect(s1.joinWhiteSpace(), 'hello 520 你 好');
    expect(s2.joinWhiteSpace(), 'a 1 b 2 c 3 哈 4 de 哈 * #  ~ 6 f');
    expect(s3.joinWhiteSpace(), '😀 😃 😄 😁 😆 😅 😂 🤣 😊 😇');
  });

  group('escapeFts5', () {
    test('no tokenize', () {
      expect('github'.escapeFts5(tokenize: false), '"github"*');
      expect('github 中文'.escapeFts5(tokenize: false), '"github"*"中 文"*');
      expect(
        'hello 520 你好'.escapeFts5(tokenize: false),
        '"hello"*"520"*"你 好"*',
      );
      expect('北京欢迎你'.escapeFts5(tokenize: false), '"北 京 欢 迎 你"*');
    });

    test('tokenized', () {
      expect('github'.escapeFts5(), '"github"*');
      expect('github 中文'.escapeFts5(), '"github"*"中 文"*');
      expect('github中文'.escapeFts5(), '"github"*"中 文"*');
      expect('北京欢迎你'.escapeFts5(), '"北 京"*"欢 迎"*"你"*');
      expect('github.com'.escapeFts5(), '"github . com"*');
    }, testOn: 'mac-os');
  });

  group('mergeSiblingDigitAlphabetTokens()', () {
    test('should work for input with only letters and numbers', () {
      final input = <String>['hello', '123', 'world', '456', 'Dart'];
      final output = input.mergeSiblingDigitAlphabetTokens();
      expect(output, equals(['hello123world456Dart']));
    });

    test('should work for input with only Chinese characters', () {
      final input = <String>['你好', '世界', '再见'];
      final output = input.mergeSiblingDigitAlphabetTokens();
      expect(output, equals(input));
    });

    test(
      'should work for input with letters, numbers, and Chinese characters',
      () {
        final input = <String>['hello', '123', 'world', '你好', '456', 'Dart'];
        final output = input.mergeSiblingDigitAlphabetTokens();
        expect(output, equals(['hello123world', '你好', '456Dart']));
      },
    );

    test('should work for empty input', () {
      final input = <String>[];
      final output = input.mergeSiblingDigitAlphabetTokens();
      expect(output, equals([]));
    });

    test('should work for input with only one string', () {
      final input = <String>['hello'];
      final output = input.mergeSiblingDigitAlphabetTokens();
      expect(output, equals(input));
    });
  });
}
