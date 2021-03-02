import 'dart:ui';

extension TextRangeExtension on TextRange {
  bool get composed => start == end;
}
