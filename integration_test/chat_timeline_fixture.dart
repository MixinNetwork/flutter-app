import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/chat/chat_history_viewport.dart';
import 'package:flutter_app/ui/home/chat/chat_scroll_coordinator.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/ui/home/notifier/chat_side_notifier.dart';
import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_app/ui/provider/account_server_provider.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:provider/provider.dart' as provider;

const conversationId = '00000000-0000-4000-8000-0000000000aa';
const _users = [
  ('00000000-0000-4000-8000-000000000001', 'Alice 陈'),
  ('00000000-0000-4000-8000-000000000002', 'Bob'),
  ('00000000-0000-4000-8000-000000000003', '李小龙'),
  ('00000000-0000-4000-8000-000000000004', 'Carol ✨'),
];
const _longText =
    '这是一段比较长的消息，用来测试多行文本的布局和换行。This message mixes English and 中文, '
    'with an email test@example.com and a link '
    'https://github.com/MixinNetwork/flutter-app/pull/2066 and some emoji 🎉🚀🔥.';
const _texts = [
  '今天下午三点在会议室讨论一下新版本的发布计划，大家记得带上电脑',
  'ok 👍🏻 see https://mixin.one/blog/release-notes for details',
  '@7000 can you check this? 😀😀 thanks',
  'Short',
  _longText,
  '收到',
];

/// Creates one large JPEG so image rows pay a realistic decode cost.
Future<String> createLargeImage(Directory directory) async {
  final file = File('${directory.path}/large.jpg');
  if (!file.existsSync()) {
    final image = img.Image(width: 4000, height: 3000);
    img.fill(image, color: img.ColorRgb8(90, 140, 200));
    await file.writeAsBytes(img.encodeJpg(image, quality: 80));
  }
  return file.path;
}

/// Builds [count] messages, oldest first, with a mix of text and image rows.
List<MessageItem> buildMessages(
  int count, {
  required String imagePath,
  bool withImages = true,
}) {
  final thumb = img.Image(width: 40, height: 30);
  img.fill(thumb, color: img.ColorRgb8(90, 140, 200));
  final thumbImage = base64Encode(img.encodeJpg(thumb));
  return List.generate(count, (index) {
    final (userId, name) = _users[index % _users.length];
    final createdAt = DateTime(2026, 10).add(Duration(minutes: index * 7));
    final isImage = withImages && index % 9 == 4;
    return MessageItem(
      messageId: 'message-${index.toString().padLeft(6, '0')}',
      conversationId: conversationId,
      type: isImage ? MessageCategory.plainImage : MessageCategory.plainText,
      content: isImage ? null : _texts[index % _texts.length],
      createdAt: createdAt,
      status: MessageStatus.read,
      userId: userId,
      userFullName: name,
      userIdentityNumber: '${7000 + index % _users.length}',
      isVerified: false,
      sharedUserIsVerified: false,
      pinned: false,
      mediaStatus: isImage ? MediaStatus.done : null,
      mediaUrl: isImage ? imagePath : null,
      mediaWidth: isImage ? 4000 : null,
      mediaHeight: isImage ? 3000 : null,
      thumbImage: isImage ? thumbImage : null,
      conversionCategory: ConversationCategory.group,
    );
  });
}

/// Serves a window of [pool] like the real controller: starts at the latest
/// messages and prepends a page on every [before] call.
class FakeMessageController extends ValueNotifier<MessageState>
    implements MessageController {
  FakeMessageController(this.pool, {this.pageSize = 30, int initial = 60})
    : _start = pool.length - initial,
      super(
        MessageState(
          conversationId: conversationId,
          bottom: pool.sublist(pool.length - initial),
          isLatest: true,
        ),
      );

  List<MessageItem> pool;
  final int pageSize;
  Object? refreshKey;
  int _start;

  /// Switches to another conversation, like the real controller does when the
  /// selected conversation changes.
  void open(
    List<MessageItem> messages, {
    required Object refreshKey,
    int initial = 60,
  }) {
    pool = messages;
    this.refreshKey = refreshKey;
    _start = messages.length - initial;
    value = MessageState(
      conversationId: conversationId,
      bottom: messages.sublist(_start),
      isLatest: true,
      refreshKey: refreshKey,
    );
  }

  @override
  void before() {
    if (_start == 0) return;
    final next = (_start - pageSize).clamp(0, _start);
    final page = pool.sublist(next, _start);
    _start = next;
    value = MessageState(
      conversationId: conversationId,
      top: [...page.reversed, ...value.top],
      center: value.center,
      bottom: value.bottom,
      isLatest: true,
      isOldest: _start == 0,
      refreshKey: refreshKey,
    );
  }

  @override
  void after() {}

  /// Appends one incoming message at the bottom, like a live update.
  void append(MessageItem message) {
    value = MessageState(
      conversationId: conversationId,
      top: value.top,
      center: value.center,
      bottom: [...value.bottom, message],
      isLatest: true,
      isOldest: value.isOldest,
      refreshKey: refreshKey,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountServer implements AccountServer {
  // The first fixture user is the signed-in user, so both bubble sides render.
  @override
  String get userId => _users.first.$1;

  @override
  String convertAbsolutePath(
    String category,
    String conversationId,
    String? fileName, [
    bool isTranscript = false,
  ]) => fileName ?? '';

  @override
  Future<void> markMentionRead(String messageId, String conversationId) async {}

  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReadyDatabaseOpener extends DatabaseOpener {
  _ReadyDatabaseOpener(Database database) {
    state = AsyncValue.data(database);
  }
}

Database createFixtureDatabase() => Database(
  MixinDatabase(NativeDatabase.memory()),
  FtsDatabase(NativeDatabase.memory()),
);

class _ReadyAccountServerOpener extends AccountServerOpener {
  _ReadyAccountServerOpener() {
    state = AsyncValue.data(_FakeAccountServer());
  }
}

/// The real chat timeline (viewport, rows, scroll coordinator) over [controller].
class ChatTimelineFixture extends StatelessWidget {
  const ChatTimelineFixture({
    required this.controller,
    required this.blinkNotifier,
    required this.database,
    this.width,
    super.key,
  });

  final FakeMessageController controller;
  final BlinkNotifier blinkNotifier;
  final Database database;
  final double? width;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      databaseProvider.overrideWith((ref) => _ReadyDatabaseOpener(database)),
      mentionCacheProvider.overrideWithValue(MentionCache(null)),
      settingProvider.overrideWith((ref) => SettingChangeNotifier()),
      accountServerProvider.overrideWith((ref) => _ReadyAccountServerOpener()),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        Localization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: BrightnessData(
        value: 0,
        brightnessThemeData: lightBrightnessThemeData,
        child: provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider<BlinkNotifier>.value(
              value: blinkNotifier,
            ),

            provider.ChangeNotifierProvider(create: (_) => ChatSideNotifier()),
            provider.ChangeNotifierProvider(
              create: (context) => SearchConversationKeywordNotifier(
                chatSideNotifier: context.read<ChatSideNotifier>(),
              ),
            ),
            provider.Provider(
              create: (_) => ChatScrollCoordinator(),
              dispose: (_, coordinator) => coordinator.dispose(),
            ),
          ],
          child: Material(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: provider.ChangeNotifierProvider<MessageController>.value(
                  value: controller,
                  child: const ChatHistoryViewport(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
