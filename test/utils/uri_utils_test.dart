import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/qr_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _perpsUrl =
    'https://mixin.one/trade?type=perps&market=799e2fdc-2c5d-3372-a347-c05c9a225d49';

void main() {
  Future<List<Uri>> open(WidgetTester tester, String url) async {
    late BuildContext context;
    await tester.pumpWidget(
      BrightnessData(
        value: 0,
        brightnessThemeData: lightBrightnessThemeData,
        child: MaterialApp(
          localizationsDelegates: const [Localization.delegate],
          supportedLocales: Localization.delegate.supportedLocales,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final opened = <Uri>[];
    // The dialog future completes only when the dialog closes.
    openUri(
      context,
      url,
      fallbackHandler: (uri) async {
        opened.add(uri);
        return true;
      },
    ).ignore();
    await tester.pumpAndSettle();
    return opened;
  }

  for (final url in [
    _perpsUrl,
    'https://mixin.one/trade?type=limit',
    'mixin://trade?type=perps',
  ]) {
    testWidgets('$url shows the open-on-phone QR code', (tester) async {
      expect(await open(tester, url), isEmpty);
      expect(find.byType(QrCode), findsOneWidget);
    });
  }

  testWidgets('a mixin.one page still opens in the fallback handler', (
    tester,
  ) async {
    const url = 'https://mixin.one/pages/x';
    expect(await open(tester, url), [Uri.parse(url)]);
    expect(find.byType(QrCode), findsNothing);
  });

  test('trade links are Mixin action URLs', () {
    expect(Uri.parse(_perpsUrl).isMixinActionUrl, isTrue);
    expect(Uri.parse('https://mixin.one/pages/x').isMixinActionUrl, isFalse);
  });
}
