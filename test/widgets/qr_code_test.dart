import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/qr_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a QR code when Q-level capacity is exceeded', (
    tester,
  ) async {
    final data = List.filled(1741, 'a').join();

    await tester.pumpWidget(_app(data));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('shows an error when L-level capacity is exceeded', (
    tester,
  ) async {
    final data = List.filled(3000, 'a').join();

    await tester.pumpWidget(_app(data));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Cannot recognize the QR code'), findsOneWidget);
  });
}

Widget _app(String data) => MaterialApp(
  localizationsDelegates: const [Localization.delegate],
  supportedLocales: Localization.delegate.supportedLocales,
  home: Scaffold(body: QrCode(data: data, dimension: 240)),
);
