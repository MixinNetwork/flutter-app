import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/provider/ui_context_providers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets(
    'UiContextScope does not modify providers during build',
    (tester) async {
      FlutterErrorDetails? capturedError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        capturedError = details;
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              Localization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: Localization.delegate.supportedLocales,
            home: const UiContextScope(child: SizedBox()),
          ),
        ),
      );
      await tester.pump();

      expect(
        capturedError?.exceptionAsString(),
        isNot(
          contains(
            'Tried to modify a provider while the widget tree was building',
          ),
        ),
      );
    },
  );
}
