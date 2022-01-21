import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/locale.dart';

import '../logger.dart';

const _kFallbackFontName = 'DroidSansFallbackFull';

bool _fallbackFontsLoaded = false;

Future<void> loadFallbackFonts() async {
  if (!Platform.isLinux) {
    return;
  }

  // Skip load fallback fonts if current system language is en.
  // See more: https://github.com/flutter/flutter/issues/90951
  final locale = Locale.parse(Platform.localeName);
  i('platform locale: $locale');
  if (locale.languageCode == 'en') {
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
  final file =
      File('/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf');
  if (!file.existsSync()) {
    w('failed to load DroidSansFallbackFull.ttf');
    return;
  }
  try {
    final bytes = await file.readAsBytes();
    await loadFontFromList(bytes, fontFamily: _kFallbackFontName);
  } catch (e, stacktrace) {
    w('failed to load DroidSansFallbackFull.ttf, $e $stacktrace');
  }
}

String? _getFallbackFontFamily() {
  if (Platform.isLinux) {
    if (_fallbackFontsLoaded) {
      return _kFallbackFontName;
    }
    w('did not loaded fallback fonts yet.');
  }
  return null;
}

extension ApplyFontsExtension on ThemeData {
  ThemeData withFallbackFonts() {
    final fallbackFont = _getFallbackFontFamily();
    if (fallbackFont == null) {
      return this;
    }
    return copyWith(
      textTheme: textTheme.applyFonts(fallbackFont, null),
      primaryTextTheme: primaryTextTheme.applyFonts(fallbackFont, null),
    );
  }
}

extension _TextTheme on TextTheme {
  TextTheme applyFonts(String? fontFamily, List<String>? fontFamilyFallback) =>
      copyWith(
        displayLarge: displayLarge?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        displayMedium: displayMedium?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        displaySmall: displaySmall?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        headlineLarge: headlineLarge?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        headlineMedium: headlineMedium?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        headlineSmall: headlineSmall?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        titleLarge: titleLarge?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        titleMedium: titleMedium?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        titleSmall: titleSmall?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        bodyLarge: bodyLarge?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        bodyMedium: bodyMedium?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        bodySmall: bodySmall?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        labelLarge: labelLarge?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        labelMedium: labelMedium?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
        labelSmall: labelSmall?.copyWith(
            fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
      );
}
