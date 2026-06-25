import 'package:flutter_app/ui/home/chat/chat_send_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('complete clears quote and requests latest', () async {
    var clearedQuote = false;
    var requestedLatest = false;

    ChatSendOutcome(
      clearQuote: () => clearedQuote = true,
      jumpToLatest: () async => requestedLatest = true,
    ).complete();

    await Future<void>.delayed(Duration.zero);

    expect(clearedQuote, true);
    expect(requestedLatest, true);
  });

  test('complete can preserve quote while requesting latest', () async {
    var clearedQuote = false;
    var requestedLatest = false;

    ChatSendOutcome(
      clearQuote: () => clearedQuote = true,
      jumpToLatest: () async => requestedLatest = true,
    ).complete(clearQuote: false);

    await Future<void>.delayed(Duration.zero);

    expect(clearedQuote, false);
    expect(requestedLatest, true);
  });
}
