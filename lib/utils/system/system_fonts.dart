import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../emoji.dart';
import '../logger.dart';

bool _fallbackFontsLoaded = false;

String? loadedFallbackFonts;

/// The system CJK font family on Linux. Text whose fonts lack a character
/// falls back through fontconfig for every paragraph, which costs about 3 ms
/// per paragraph, so the theme lists a CJK family and the emoji family.
String? _linuxCjkFamily;

// TODO(BIN): remove this when https://github.com/flutter/flutter/issues/90951 has been fixed.
Future<void> loadFallbackFonts() async {
  if (!Platform.isLinux) {
    return;
  }

  // Skip load fallback fonts if current system language is en.
  // See more: https://github.com/flutter/flutter/issues/90951
  if (PlatformDispatcher.instance.locale.languageCode == 'en') {
    try {
      final result = await Process.run('fc-match', [
        '-f',
        '%{family[0]}',
        ':lang=zh-cn',
      ]);
      final family = (result.stdout as String).trim();
      if (result.exitCode == 0 && family.isNotEmpty) _linuxCjkFamily = family;
    } catch (error) {
      w('failed to match a CJK font family: $error');
    }
    return;
  }
  if (_fallbackFontsLoaded) {
    return;
  }
  _fallbackFontsLoaded = true;

  // On some Linux systems(Ubuntu 20.04）, flutter can not render CJK fonts correctly when
  // current system language is not en.
  // https://github.com/flutter/flutter/issues/90951
  // We load the DroidSansFallbackFull font from the system and use it as a fallback.
  try {
    final matchedResult = Process.runSync('fc-match', ['-f', '%{family}']);
    if (matchedResult.exitCode != 0) {
      e('failed to get best match font family. error: ${matchedResult.stderr}');
      return;
    }
    final result = Process.runSync('fc-list', [
      '-f',
      '%{family}:%{file}\n',
      matchedResult.stdout as String,
    ]);
    final lines = const LineSplitter().convert(result.stdout as String);
    String? fontFamily;
    final fontPaths = <String>[];
    assert(lines.isNotEmpty);
    for (final line in lines) {
      // font config "family:file"
      final fontConfig = line.split(':');
      assert(
        fontConfig.length == 2,
        'font config do not match required format. $fontConfig',
      );
      if (fontFamily == null) {
        fontFamily = fontConfig.first;
        fontPaths.add(fontConfig[1]);
      } else if (fontFamily == fontConfig.first) {
        fontPaths.add(fontConfig[1]);
      } else {
        w(
          'font family not match. expect $fontFamily, but ${fontConfig.first}. line: $line',
        );
      }
    }
    if (fontPaths.isEmpty || fontFamily == null) {
      w('failed to retriver font config: $lines');
      return;
    }
    loadedFallbackFonts = fontFamily;
    for (final path in fontPaths) {
      d('load fallback fonts: $fontFamily $path');
      try {
        final file = File(path.trim());
        final bytes = file.readAsBytesSync();
        await loadFontFromList(bytes, fontFamily: fontFamily);
      } catch (e, stacktrace) {
        w('failed to load font $path, $e $stacktrace');
      }
    }
  } catch (error, stacktrace) {
    e('failed to load system fonts, error: $error, $stacktrace');
  }
}

extension ApplyFontsExtension on ThemeData {
  ThemeData withFallbackFonts() {
    final List<String> fallback;
    if (Platform.isWindows) {
      fallback = ['Microsoft Yahei', kEmojiFontFamily];
    } else if (Platform.isLinux) {
      fallback = [?_linuxCjkFamily, kEmojiFontFamily];
    } else {
      return this;
    }
    return copyWith(
      textTheme: textTheme.applyFonts(loadedFallbackFonts, fallback),
      primaryTextTheme: primaryTextTheme.applyFonts(
        loadedFallbackFonts,
        fallback,
      ),
    );
  }
}

extension _TextTheme on TextTheme {
  TextTheme applyFonts(String? fontFamily, List<String>? fontFamilyFallback) =>
      copyWith(
        displayLarge: displayLarge?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        displayMedium: displayMedium?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        displaySmall: displaySmall?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        headlineLarge: headlineLarge?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        headlineMedium: headlineMedium?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        headlineSmall: headlineSmall?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        titleLarge: titleLarge?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        titleMedium: titleMedium?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        titleSmall: titleSmall?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        bodyLarge: bodyLarge?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        bodyMedium: bodyMedium?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        bodySmall: bodySmall?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        labelLarge: labelLarge?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        labelMedium: labelMedium?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        labelSmall: labelSmall?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
      );
}
