import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/widgets/message/send_message_dialog/send_recipient.dart';
import 'package:flutter_test/flutter_test.dart';

// The confirmation row leaves about 316 px for the recipient after "To".
const _width = 316.0;

Future<void> _pump(
  WidgetTester tester, {
  String? fullName,
  String? identityNumber,
}) => tester.pumpWidget(
  MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: _width,
        child: SendRecipientLabel(
          userId: 'u-1',
          fullName: fullName,
          identityNumber: identityNumber,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a name too long for the row still leaves the whole Mixin ID '
      'in view', (tester) async {
    await _pump(
      tester,
      fullName: 'Mixin Support (7000)${'W' * 20}',
      identityNumber: '37160854',
    );
    final id = find.text(' (37160854)');
    expect(id, findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(id).didExceedMaxLines, isFalse);
    expect(
      tester
          .renderObject<RenderParagraph>(find.textContaining('Support'))
          .didExceedMaxLines,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a recipient without a name shows its Mixin ID, and one not '
      'loaded yet shows the raw id', (tester) async {
    await _pump(tester, fullName: ' ', identityNumber: '7000');
    expect(find.text('7000'), findsOneWidget);

    await _pump(tester);
    expect(find.text('u-1'), findsOneWidget);
  });
}
