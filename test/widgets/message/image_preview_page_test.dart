import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/menu.dart';
import 'package:flutter_app/widgets/message/item/image/image_preview_page.dart';
import 'package:flutter_app/widgets/message/item/post_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class _TestDatabaseOpener extends DatabaseOpener {
  _TestDatabaseOpener(Database database) {
    state = AsyncValue.data(database);
  }
}

void main() {
  setUpAll(EventBus.initialize);

  testWidgets('Escape closes the image preview route', (tester) async {
    final database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    addTearDown(database.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith(
            (ref) => _TestDatabaseOpener(database),
          ),
        ],
        child: BrightnessData(
          value: 0,
          brightnessThemeData: lightBrightnessThemeData,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    showGeneralDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      barrierLabel: MaterialLocalizations.of(
                        context,
                      ).modalBarrierDismissLabel,
                      pageBuilder: (_, _, _) => const ImagePreviewPage(
                        conversationId: 'conversation',
                        messageId: 'message',
                        isTranscriptPage: false,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.byType(ImagePreviewPage), findsOneWidget);
    expect(find.byType(CustomContextMenuWidget), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(ImagePreviewPage), findsNothing);
  });

  testWidgets('Escape closes the post preview route', (tester) async {
    final message = MessageItem(
      messageId: 'post',
      conversationId: 'conversation',
      type: MessageCategory.plainPost,
      content: 'post',
      createdAt: DateTime(2026),
      status: MessageStatus.read,
      userId: 'user',
      userIdentityNumber: '0',
      isVerified: false,
      sharedUserIsVerified: false,
      pinned: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingProvider.overrideWith((ref) => SettingChangeNotifier()),
        ],
        child: BrightnessData(
          value: 0,
          brightnessThemeData: lightBrightnessThemeData,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    showGeneralDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      barrierLabel: MaterialLocalizations.of(
                        context,
                      ).modalBarrierDismissLabel,
                      pageBuilder: (_, _, _) => PostPreview(message: message),
                    );
                  },
                  child: const Text('open post'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open post'));
    await tester.pump();
    expect(find.byType(PostPreview), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(PostPreview), findsNothing);
  });
}
