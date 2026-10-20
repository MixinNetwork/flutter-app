import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/reg_exp_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void match(RegExp regExp, String text, String uri) {
  final matches = regExp.allMatches(text).toList();
  expect(matches, isNotEmpty, reason: text);
  expect(matches.length, 1, reason: text);

  expect(matches.first[0], uri);
}

void main() {
  final bigText = List.generate(1024 * 64, (index) => 'a').join();

  group('uri', () {
    test('speed', () {
      final timer = Stopwatch()..start();
      final matches = uriRegExp.allMatches(bigText).toList();
      timer.stop();

      expect(timer.elapsedMilliseconds, lessThan(30));
      expect(matches, <RegExpMatch>[]);

      if (kDebugMode) {
        print('uri match large text: ${timer.elapsedMilliseconds}ms');
      }
    });

    const uris = [
      'https://www.mixin.one',
      'https://www.mixin.one/',
      'https://www.mixin.one/foo',
      'https://www.mixin.one/foo/',
      'https://www.mixin.one/foo/bar',
      'https://www.mixin.one/foo/bar.html',
      'https://www.mixin.one/foo/bar.php',
      'http://www.mixin.one/path/to/page.html?key=value',
      'ftp://ftp.example.com/files/file.txt',
      'https://en.wikipedia.org/wiki/Regularexpression',
      'http://localhost:8080/index.html',
      'https://www.google.com/search?q=test&rlz=1C1GCEAenUS832US832&oq=test&aqs=chrome..69i57j0l7.2117j1j7&sourceid=chrome&ie=UTF-8',
      'smb://server/share/file.txt',
      'git+ssh://github.com/user/repo.git',
      'ftps://ftp.example.com/files/file.txt',
      'rsync://example.com/module/file.txt',
      'ldap://ldap.example.com/dc=example,dc=com',
      'svn+ssh://svn.example.com/project/trunk',
      'ssh://user@host.com/path/to/file.txt',
      'telnet://telnet.example.com:23/',
      'sftp://example.com/user/file.txt',
      'news:alt.test',
      'gopher://gopher.example.com/00/',
      'bitcoin:HASHVALUE',
    ];

    test('syntax', () {
      for (final uri in uris) {
        match(uriRegExp, uri, uri);
      }
    });

    test('accuracy', () {
      for (final uri in uris) {
        match(uriRegExp, '($uri)', uri);
        match(uriRegExp, '[$uri]', uri);
        match(uriRegExp, 'url: $uri', uri);
        match(uriRegExp, '链接：$uri', uri);
        match(uriRegExp, '$uri，接下来', uri);
        match(uriRegExp, '$uri。', uri);
        match(uriRegExp, '你看看这个$uri可以吗', uri);
      }
    });
  }, skip: true);

  group('bot number', () {
    test('speed', () {
      final timer = Stopwatch()..start();
      final matches = botNumberRegExp.allMatches(bigText).toList();
      timer.stop();

      expect(timer.elapsedMilliseconds, lessThan(10));
      expect(matches, <RegExpMatch>[]);

      if (kDebugMode) {
        print('bot number match large text: ${timer.elapsedMilliseconds}ms');
      }
    });

    const botNumber = 7000123456;

    test('syntax', () {
      match(botNumberRegExp, '$botNumber', '$botNumber');
    });

    test('accuracy', () {
      match(botNumberRegExp, '($botNumber)', '$botNumber');
      match(botNumberRegExp, 'foo${botNumber}bar', '$botNumber');
      match(botNumberRegExp, '福$botNumber报', '$botNumber');
      match(botNumberRegExp, ':$botNumber,', '$botNumber');
      match(botNumberRegExp, '：$botNumber。', '$botNumber');
    });
  }, skip: true);

  group('mail', () {
    test('speed', () {
      final timer = Stopwatch()..start();
      final matches = mailRegExp.allMatches(bigText).toList();
      timer.stop();

      expect(timer.elapsedMilliseconds, lessThan(20));
      expect(matches, <RegExpMatch>[]);

      if (kDebugMode) {
        print('mail match large text: ${timer.elapsedMilliseconds}ms');
      }
    });

    final mails = [
      'user@example.com',
      'jane.doe@example.co.uk',
      'john+test@gmail.com',
      'jane-doe@my-domain.org',
      'john.smith@mail.example.com',
      'jane.doe.123@example.com',
      'user@localhost.localdomain',
      'john_doe@mail.example.com',
      'jane.doe+test@example.com',
      'user@sub.domain.example.com',
      'jane.doe@my_domain.org',
      'john.smith1234@mail.example.com',
      'user@xn--bcher-kva.ch', // IDN domain
      'jane.doe@email.example.travel', // new TLD
      'john.smith@my-domain.co.uk',
      'user@my.long.email.address.com',
      'jane.doe@mail.example.museum', // museum TLD
      'john.smith@email.example.foundation', // foundation TLD
      'user@my.fake.tld', // not a real TLD, but still valid email format
    ];

    test('syntax', () {
      for (final mail in mails) {
        match(mailRegExp, mail, mail);
      }
    });

    test('accuracy', () {
      for (final mail in mails) {
        match(mailRegExp, '($mail)', mail);
        match(mailRegExp, '[$mail]', mail);
        match(mailRegExp, 'url: $mail', mail);
        match(mailRegExp, '链接：$mail', mail);
        match(mailRegExp, '$mail，接下来', mail);
        match(mailRegExp, '$mail。', mail);
        match(mailRegExp, '你看看这个$mail可以吗', mail);
      }
    });
  }, skip: true);
}
