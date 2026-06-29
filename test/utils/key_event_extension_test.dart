import 'package:flutter/services.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetExtension.hasAltKey', () {
    test('returns true for either Alt key', () {
      expect({LogicalKeyboardKey.altLeft}.hasAltKey, isTrue);
      expect({LogicalKeyboardKey.altRight}.hasAltKey, isTrue);
      expect({LogicalKeyboardKey.alt}.hasAltKey, isTrue);
    });

    test('returns false when no Alt key is pressed', () {
      expect({LogicalKeyboardKey.metaLeft}.hasAltKey, isFalse);
      expect(<LogicalKeyboardKey>{}.hasAltKey, isFalse);
    });
  });
}
