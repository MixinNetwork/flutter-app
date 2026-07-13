import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/provider/chat_navigation_intent_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('requestLatestJump emits a fresh one-shot key each time', () {
    final notifier = ChatNavigationIntentNotifier()
      ..requestLatestJump('conversation-1');
    final firstKey = notifier.state.latestJumpRequestKey;

    notifier.requestLatestJump('conversation-1');
    final secondKey = notifier.state.latestJumpRequestKey;

    expect(firstKey, isNotNull);
    expect(secondKey, isNotNull);
    expect(secondKey, isNot(same(firstKey)));
    expect(notifier.state.latestJumpConversationId, 'conversation-1');

    expect(notifier.takeLatestJump(secondKey!, 'conversation-1'), isTrue);
    expect(notifier.state.latestJumpRequestKey, isNull);
    expect(notifier.state.latestJumpConversationId, isNull);
  });

  test('takeLatestJump consumes a request for another conversation', () {
    final notifier = ChatNavigationIntentNotifier()
      ..requestLatestJump('conversation-1');
    final requestKey = notifier.state.latestJumpRequestKey;

    expect(notifier.takeLatestJump(requestKey!, 'conversation-2'), isFalse);
    expect(notifier.state.latestJumpRequestKey, isNull);
    expect(notifier.state.latestJumpConversationId, isNull);
  });

  testWidgets('latest jump consumption is deferred until after build', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: _LatestJumpEffect(),
        ),
      ),
    );

    container
        .read(chatNavigationIntentProvider.notifier)
        .requestLatestJump('conversation-1');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      container.read(chatNavigationIntentProvider).latestJumpRequestKey,
      isNull,
    );
  });

  testWidgets('a stale post-frame callback does not consume a newer request', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: _LatestJumpEffect(),
        ),
      ),
    );

    container
        .read(chatNavigationIntentProvider.notifier)
        .requestLatestJump('conversation-1');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      container
          .read(chatNavigationIntentProvider.notifier)
          .requestLatestJump('conversation-2');
    });
    await tester.pump();

    expect(
      container.read(chatNavigationIntentProvider).latestJumpConversationId,
      'conversation-2',
    );
  });
}

class _LatestJumpEffect extends HookConsumerWidget {
  const _LatestJumpEffect();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(chatNavigationIntentProvider);
    useEffect(() {
      if (request.latestJumpRequestKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(chatNavigationIntentProvider.notifier)
              .takeLatestJump(request.latestJumpRequestKey!, 'conversation-1');
        });
      }
      return null;
    }, [request.latestJumpRequestKey]);
    return const SizedBox();
  }
}
