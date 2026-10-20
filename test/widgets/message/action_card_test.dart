import 'package:flutter_app/widgets/message/item/action/action_data.dart';
import 'package:flutter_app/widgets/message/item/action_card/action_card_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared actions follow Android send-prefix exclusions', () {
    final cases = {
      'mixin://apps/example': true,
      'MIXIN://users/example': true,
      'https://example.com': true,
      'http://example.com': true,
      'custom://example': true,
      'mixin://send?user=example': false,
      'mixin://mixin.one/send?text=hello': false,
      'https://mixin.one/send?user=example': false,
      'MiXiN://SeNd': false,
      'MIXIN://MIXIN.ONE/SEND': false,
      'HTTPS://MIXIN.ONE/SEND': false,
      'mixin://sender': false,
    };
    AppCardData card(List<String> actions) => AppCardData(
      '',
      '',
      'title',
      'description',
      '',
      '',
      true,
      actions.map((action) => ActionData('button', '', action)).toList(),
      '',
      null,
    );
    for (final entry in cases.entries) {
      expect(card([entry.key]).canShareActions, entry.value, reason: entry.key);
    }
    expect(card([]).canShareActions, isTrue);
    expect(
      card([
        'mixin://apps/example',
        'mixin://send?user=example',
      ]).canShareActions,
      isFalse,
    );
  });

  test('test generate copy', () {
    final tests = [
      (
        'test title',
        'test description',
        'titletest description',
        'title\ntest description',
      ),
      ('', '', '', ''),
      ('', 'test description', 'test description', 'test description'),
      ('test title', '', 'test title', 'test title'),
      ('test title', 'test description', 'title', 'title'),
      ('test title', 'test description', 'test', 'test'),
      ('test title', 'test description', 'test title', 'test title'),
      ('test title', 'test description', 'test titlet', 'test title\nt'),
      ('test title', 'test description', 'test titletest', 'test title\ntest'),
      (
        'test title',
        'test description',
        'test titletest description',
        'test title\ntest description',
      ),
    ];

    for (final test in tests) {
      final data = AppCardData(
        '',
        '',
        test.$1,
        test.$2,
        '',
        '',
        true,
        [ActionData('', '', '')],
        '',
        null,
      );
      expect(data.generateCopyTextWithBreakLine(test.$3), test.$4);
    }
  });
}
