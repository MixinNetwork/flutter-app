import 'dart:convert';

import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/provider/account_server_provider.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/high_light_text.dart';
import 'package:flutter_app/widgets/message/item/quote_message.dart';
import 'package:flutter_app/widgets/message/item/recall_message.dart';
import 'package:flutter_app/widgets/message/message_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

const _admin = '00000000-0000-4000-8000-000000000001';
const _me = '00000000-0000-4000-8000-000000000002';
const _sender = '00000000-0000-4000-8000-000000000003';

void main() {
  for (final (locale, byOther, byMe) in [
    (
      const Locale('en'),
      'Yang deleted this message.',
      'You deleted this message',
    ),
    (const Locale('zh'), 'Yang撤回了一条消息', '你撤回了一条消息'),
  ]) {
    group('in ${locale.toLanguageTag()}', () {
      setUp(() => Localization.load(locale));

      testWidgets('a recalled message names who recalled it', (tester) async {
        await tester.pumpWidget(
          _scope(
            Column(
              children: [
                _recalled('1', actorId: _admin, actorName: 'Yang'),
                _recalled('2', actorId: _me, actorName: 'Me'),
              ],
            ),
          ),
        );

        expect(find.textContaining(byOther), findsOneWidget);
        expect(find.textContaining(byMe), findsOneWidget);
      });

      testWidgets('a quote of a recalled message names who recalled it', (
        tester,
      ) async {
        await tester.pumpWidget(
          _scope(
            QuoteMessage(
              messageId: 'reply',
              quoteMessageId: 'quoted',
              quoteContent: jsonEncode({
                'message_id': 'quoted',
                'conversation_id': 'conversation',
                'user_id': _sender,
                'user_full_name': 'Sender',
                'user_identity_number': '1',
                'type': MessageCategory.messageRecall,
                'createdAt': 1767225600000,
                'status': 'DELIVERED',
                'participant_user_id': _admin,
                'participant_full_name': 'Yang',
              }),
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (w) => w is CustomText && w.text == byOther,
          ),
          findsOneWidget,
        );
      });
    });
  }
}

Widget _recalled(
  String id, {
  required String actorId,
  required String actorName,
}) => MessageContext.fromMessageItem(
  message: MessageItem(
    messageId: id,
    conversationId: 'conversation',
    type: MessageCategory.messageRecall,
    createdAt: DateTime(2026),
    status: MessageStatus.delivered,
    userId: _sender,
    userFullName: 'Sender',
    relationship: UserRelationship.friend,
    participantUserId: actorId,
    participantFullName: actorName,
    userIdentityNumber: '1',
    isVerified: false,
    sharedUserIsVerified: false,
    pinned: false,
  ),
  child: const RecallMessage(),
);

Widget _scope(Widget child) => ProviderScope(
  overrides: [
    databaseProvider.overrideWith((ref) => DatabaseOpener()),
    mentionCacheProvider.overrideWithValue(MentionCache(null)),
    settingProvider.overrideWith((ref) => SettingChangeNotifier()),
    accountServerProvider.overrideWith((ref) => _ReadyAccountServer()),
  ],
  child: MaterialApp(
    home: BrightnessData(
      value: 0,
      brightnessThemeData: lightBrightnessThemeData,
      child: child,
    ),
  ),
);

class _ReadyAccountServer extends AccountServerOpener {
  _ReadyAccountServer() {
    state = AsyncValue.data(_FakeAccountServer());
  }
}

class _FakeAccountServer implements AccountServer {
  @override
  String get userId => _me;

  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
