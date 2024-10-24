import 'package:flutter_app/widgets/message/item/transfer/inscription_message/inscription_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inscription text display', () {
    final tests = [
      ('1 .mao', '1■.mao'),
      ('mixin.mao', 'mixin.mao'),
      ('🇨🇳.mao', '🇨🇳.mao'),
      ('\u{0001}.mao', '■.mao'),
      ('\u{008C}.mao', '■.mao'),
      ('\u{200B}.mao', '■.mao'),
      ('\tmao', '■mao'),
      ('\nmao', '■mao'),
      ('\rmao', '■mao'),
      ('\u{FEFF}mao', '■mao'),
      (' mao ', '■mao■'),
      ('\u{202F}.mao', '■.mao'),
      ('\u{2060}.mao', '■.mao'),
      ('\u{200E}left', '■left'),
      ('\u{200F}right', '■right'),
    ];
    for (final test in tests) {
      expect(inscriptionDisplayContent(test.$1), test.$2, reason: test.$1);
    }
  });
}
