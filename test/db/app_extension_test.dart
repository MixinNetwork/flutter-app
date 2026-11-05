import 'package:flutter_app/db/extension/app.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  App app(String? resourcePatterns) => App(
    appId: 'app',
    appNumber: '7000',
    homeUri: 'https://bot.example/',
    redirectUri: 'https://bot.example/',
    name: 'bot',
    iconUrl: '',
    description: '',
    appSecret: '',
    creatorId: 'creator',
    resourcePatterns: resourcePatterns,
  );

  test('matches the scheme, host and path prefix of a pattern', () {
    final bot = app('[https://bot.example/trusted/, https://cdn.example]');
    expect(bot.matchesResource('https://bot.example/trusted/page?a=1'), true);
    expect(bot.matchesResource('https://BOT.example/trusted/'), true);
    expect(bot.matchesResource('https://cdn.example/anything'), true);
    expect(bot.matchesResource('https://bot.example/untrusted/'), false);
    expect(bot.matchesResource('http://bot.example/trusted/'), false);
    expect(bot.matchesResource('https://evil.example/trusted/'), false);
    expect(bot.matchesResource('https://bot.example.evil/trusted/'), false);
  });

  test('matches nothing without patterns or a host', () {
    expect(app(null).matchesResource('https://bot.example/'), false);
    expect(app('[]').matchesResource('https://bot.example/'), false);
    expect(app('[https://bot.example]').matchesResource('about:blank'), false);
  });
}
