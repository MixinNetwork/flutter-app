import 'package:flutter_app/widgets/message/item/action/action_data.dart';
import 'package:flutter_app/widgets/message/item/action_card/action_card_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test generate copy', () {
    final tests = [
      (
        'test title',
        'test description',
        'titletest description',
        'title\ntest description'
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
        'test title\ntest description'
      ),
    ];

    for (final test in tests) {
      final data = AppCardData('', '', test.$1, test.$2, '', '', true,
          [ActionData('', '', '')], '', null);
      expect(data.generateCopyTextWithBreakLine(test.$3), test.$4);
    }
  });
}
