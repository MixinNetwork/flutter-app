import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'extension/extension.dart';

MarkdownStyleSheet markdownStyleSheet(BuildContext context) {
  final baseStyle = TextStyle(fontSize: 14, color: context.theme.text);

  return MarkdownStyleSheet(
    a: baseStyle.copyWith(
      color: context.theme.accent,
    ),
    p: baseStyle,
    code: baseStyle.copyWith(
      backgroundColor: context.theme.background,
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
      color: context.theme.primary,
    ),
    listBullet: baseStyle,
    tableHead: baseStyle.copyWith(
      fontWeight: FontWeight.w600,
    ),
    tableBody: baseStyle,
    tableHeadAlign: TextAlign.center,
    tableCellsDecoration: BoxDecoration(
      color: context.theme.background,
    ),
    blockquoteDecoration: BoxDecoration(
      color: context.theme.background,
      border: Border(
        left: BorderSide(
          color: context.theme.sidebarSelected,
          width: 4,
        ),
      ),
    ),
    // codeblockPadding: const EdgeInsets.all(8),
    codeblockDecoration: BoxDecoration(
      color: context.theme.background,
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: context.theme.sidebarSelected,
          width: 1,
        ),
      ),
    ),
  );
}
