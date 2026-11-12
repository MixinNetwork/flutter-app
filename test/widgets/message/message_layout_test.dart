import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/message/message_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MessageLayout paints its content and status children', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: MessageLayout(
            spacing: 4,
            content: const SizedBox(
              width: 20,
              height: 20,
              child: ColoredBox(color: Colors.red),
            ),
            dateAndStatus: const SizedBox(
              width: 10,
              height: 10,
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byType(MessageLayout),
      paints
        ..rect(color: Colors.red)
        ..rect(color: Colors.blue),
    );
  });
}
