import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/avatar_view/avatar_view.dart';
import 'package:flutter_app/widgets/mixin_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  Future<void> pumpGroupAvatar(WidgetTester tester, String? groupIconUrl) =>
      tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ConversationAvatarWidget(
              conversationId: '2d1c4b2a-3c9f-4c3e-9a51-7f2d2b6e8a10',
              fullName: 'Group',
              groupIconUrl: groupIconUrl,
              category: ConversationCategory.group,
              groupAvatarUsers: const [],
              size: 50,
            ),
          ),
        ),
      );

  testWidgets('group with an uploaded photo shows the photo', (tester) async {
    const url = 'https://mixin-images.example/group.jpg';
    await pumpGroupAvatar(tester, url);
    // MixinImage reads the app database, which this test does not open.
    expect(tester.takeException(), isNotNull);

    final image = tester.widget<MixinImage>(find.byType(MixinImage));
    expect((image.image as NetworkImage).url, url);
  });

  testWidgets('group without an uploaded photo shows the member puzzle', (
    tester,
  ) async {
    for (final groupIconUrl in [null, '', '/data/group_avatar.png']) {
      await pumpGroupAvatar(tester, groupIconUrl);

      expect(find.byType(AvatarPuzzlesWidget), findsOneWidget);
    }
  });
}
