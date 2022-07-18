part of '../extension.dart';

extension MarkdownExtension on String {
  String postLengthOptimize([int target = 1024]) =>
      length > target ? substring(0, target) : this;

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

extension MarkdownStyleSheetExtension on BuildContext {
  MarkdownStyleSheet get markdownStyleSheet {
    final baseStyle = TextStyle(fontSize: 14, color: theme.text);

    return MarkdownStyleSheet(
      a: baseStyle.copyWith(
        color: theme.accent,
      ),
      p: baseStyle,
      code: baseStyle.copyWith(
        backgroundColor: theme.background,
        fontFamily: 'monospace',
        fontSize: baseStyle.fontSize! * 0.85,
      ),
      h1: baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: baseStyle.fontSize! + 10,
      ),
      h2: baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: baseStyle.fontSize! + 8,
      ),
      h3: baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: baseStyle.fontSize! + 6,
      ),
      h4: baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: baseStyle.fontSize! + 4,
      ),
      h5: baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: baseStyle.fontSize! + 2,
      ),
      h6: baseStyle.copyWith(
        fontWeight: FontWeight.w500,
      ),
      blockquote: baseStyle,
      img: baseStyle,
      checkbox: baseStyle.copyWith(
        color: theme.primary,
      ),
      listBullet: baseStyle,
      tableHead: baseStyle.copyWith(
        fontWeight: FontWeight.w600,
      ),
      tableBody: baseStyle,
      tableHeadAlign: TextAlign.center,
      tableCellsDecoration: BoxDecoration(
        color: theme.background,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.background,
        border: Border(
          left: BorderSide(
            color: theme.sidebarSelected,
            width: 4,
          ),
        ),
      ),
      // codeblockPadding: const EdgeInsets.all(8),
      codeblockDecoration: BoxDecoration(
        color: theme.background,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.sidebarSelected,
          ),
        ),
      ),
    );
  }
}
