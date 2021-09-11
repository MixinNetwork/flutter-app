part of '../extension.dart';

extension RegExpExtension on RegExp {
  Iterable<RegExpMatch> allMatchesAndSort(String input, [int start = 0]) =>
      allMatches(input, start).toList()
        ..sort((a, b) => b[0]!.length - a[0]!.length);
}
