import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart';

extension MarkdownExtension on String {
  String postLengthOptimize() {
    if (length > 1024) {
      return substring(0, 1024);
    } else {
      return this;
    }
  }

  String postOptimize() => split('\n').take(20).join('\n').postLengthOptimize();

  String get postOptimizeMarkdown {
    final lines = const LineSplitter().convert(postOptimize());
    final astNodes = Document().parseLines(lines);
    return astNodes
        .map((e) => e.textContent)
        .join()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

MarkdownStyleSheet markdownStyleSheet(BuildContext context) {
  final baseStyle =
      TextStyle(fontSize: 14, color: BrightnessData.themeOf(context).text);

  return MarkdownStyleSheet(
    a: baseStyle.copyWith(
      color: BrightnessData.themeOf(context).accent,
    ),
    p: baseStyle,
    code: baseStyle.copyWith(
      backgroundColor: BrightnessData.themeOf(context).background,
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
      color: BrightnessData.themeOf(context).primary,
    ),
    listBullet: baseStyle,
    tableHead: baseStyle.copyWith(
      fontWeight: FontWeight.w600,
    ),
    tableBody: baseStyle,
    tableHeadAlign: TextAlign.center,
    tableCellsDecoration: BoxDecoration(
      color: BrightnessData.themeOf(context).background,
    ),
    blockquoteDecoration: BoxDecoration(
      color: BrightnessData.themeOf(context).background,
      border: Border(
        left: BorderSide(
          color: BrightnessData.themeOf(context).sidebarSelected,
          width: 4,
        ),
      ),
    ),
    // codeblockPadding: const EdgeInsets.all(8),
    codeblockDecoration: BoxDecoration(
      color: BrightnessData.themeOf(context).background,
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: BrightnessData.themeOf(context).sidebarSelected,
          width: 1,
        ),
      ),
    ),
  );
}
