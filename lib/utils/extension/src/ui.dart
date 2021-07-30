part of '../extension.dart';

extension TextRangeExtension on TextRange {
  bool get composed => start == end;
}
