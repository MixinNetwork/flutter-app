import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('an unknown error code shows the code and the message', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [Localization.delegate],
        supportedLocales: Localization.delegate.supportedLocales,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      context.getMixinErrorStringByCode(10104, 'address generating.'),
      'ERROR: 10104 address generating.',
    );
  });
}
