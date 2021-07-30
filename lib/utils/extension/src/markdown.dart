part of '../extension.dart';

extension MarkdownExtension on String {
  String postLengthOptimize([int target = 1024]) {
    if (length > target) {
      return substring(0, target);
    } else {
      return this;
    }
  }

  String postOptimize([int lines = 20]) =>
      LineSplitter.split(this).take(lines).join('\r\n').postLengthOptimize();

  String get postOptimizeMarkdown {
    final lines = const LineSplitter().convert(postOptimize());
    final astNodes = Document().parseLines(lines);
    return astNodes
        .map((e) => e.textContent)
        .join()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
