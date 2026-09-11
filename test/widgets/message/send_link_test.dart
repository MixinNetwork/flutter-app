@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/encrypt_category.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/notifier/conversation_list_controller.dart';
import 'package:flutter_app/ui/provider/account_server_provider.dart';
import 'package:flutter_app/ui/provider/conversation_provider.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/auth.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/buttons.dart';
import 'package:flutter_app/widgets/mixin_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart' as provider;

const _user = '00000000-0000-4000-8000-000000000001';
const _self = '00000000-0000-4000-8000-000000000002';
const _conversation = '00000000-0000-4000-8000-000000000003';

class _ConversationList extends ValueNotifier<ConversationListState>
    implements ConversationListController {
  _ConversationList() : super(const ConversationListState());
  @override
  ConversationListState get state => const ConversationListState();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Server implements AccountServer {
  final sent = <Invocation>[];
  @override
  String get userId => _self;
  @override
  Future<List<User>?> refreshUsers(
    List<String> ids, {
    bool force = false,
  }) async => [
    const User(userId: _user, identityNumber: '7001', fullName: 'Alice'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #sendTextMessage ||
        invocation.memberName == #sendImageMessageByUrl) {
      sent.add(invocation);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _ServerState extends StateNotifier<AsyncValue<AccountServer>>
    implements AccountServerOpener {
  _ServerState(AccountServer server) : super(AsyncValue.data(server));
  void replace(AccountServer server) => state = AsyncValue.data(server);
  @override
  Future<void> dispose() async => super.dispose();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DatabaseState extends StateNotifier<AsyncValue<Database>>
    implements DatabaseOpener {
  _DatabaseState(Database database) : super(AsyncValue.data(database));
  @override
  Future<void> dispose() async => super.dispose();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ConversationState extends StateNotifier<ConversationState?>
    implements ConversationStateNotifier {
  _ConversationState()
    : super(
        const ConversationState(
          conversationId: _conversation,
          userId: _user,
          refreshKey: 0,
        ),
      );
  void clear() => state = null;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #focus) {
      state = invocation.positionalArguments.first as ConversationState;
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late Database database;
  late _Server server;
  late ProviderContainer container;
  late BuildContext context;

  setUpAll(EventBus.initialize);
  setUp(() async {
    database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    server = _Server();
    container = ProviderContainer(
      overrides: [
        appLockedProvider.overrideWith((ref) => false),
        accountServerProvider.overrideWith((ref) => _ServerState(server)),
        databaseProvider.overrideWith((ref) => _DatabaseState(database)),
        conversationProvider.overrideWith((ref) => _ConversationState()),
      ],
    );
    await database.mixinDatabase
        .into(database.mixinDatabase.users)
        .insert(
          const User(userId: _user, identityNumber: '7001', fullName: 'Alice'),
        );
    await database.mixinDatabase
        .into(database.mixinDatabase.conversations)
        .insert(
          Conversation(
            conversationId: _conversation,
            ownerId: _user,
            category: sdk.ConversationCategory.contact,
            createdAt: DateTime(2026),
            status: sdk.ConversationStatus.success,
          ),
        );
  });
  tearDown(() async {
    container.dispose();
    await database.dispose();
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: BrightnessData(
          value: 0,
          brightnessThemeData: lightBrightnessThemeData,
          child: OverlaySupport.global(
            child: MaterialApp(
              localizationsDelegates: const [Localization.delegate],
              supportedLocales: Localization.delegate.supportedLocales,
              home:
                  provider.ListenableProvider<ConversationListController>.value(
                    value: _ConversationList(),
                    child: Consumer(
                      builder: (ctx, ref, child) {
                        ref
                          ..watch(appLockedProvider)
                          ..watch(accountServerProvider)
                          ..watch(databaseProvider)
                          ..watch(conversationProvider);
                        context = ctx;
                        return const Scaffold();
                      },
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(
    WidgetTester tester,
    String url, {
    bool explicit = false,
  }) async {
    await tester.runAsync(() async {
      var done = false;
      unawaited(
        openUri(context, url, isExplicitSendAction: explicit).then((_) {
          done = true;
        }),
      );
      for (
        var i = 0;
        i < 100 && !done && !Navigator.of(context).canPop();
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(done || Navigator.of(context).canPop(), isTrue);
    });
    await tester.pumpAndSettle();
  }

  String link(String category, String data, {bool user = true}) => Uri(
    scheme: 'mixin',
    host: 'send',
    queryParameters: {
      'category': category,
      'data': base64Encode(utf8.encode(data)),
      if (user) 'user': _user,
    },
  ).toString();

  testWidgets('external text waits for confirmation and cancel does not send', (
    tester,
  ) async {
    await mount(tester);
    final longText = List.filled(200, 'hello').join('\n');
    await open(tester, '${link('text', longText)}&isExplicitSendAction=true');
    expect(server.sent, isEmpty);
    expect(find.text(longText), findsOneWidget);
    expect(find.text('Alice (7001)'), findsOneWidget);
    await tester.tap(find.byType(MixinCloseButton));
    await tester.pumpAndSettle();
    expect(server.sent, isEmpty);
    await open(tester, link('text', 'hello'));
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(server.sent, hasLength(1));
    expect(server.sent.single.namedArguments[#recipientId], _user);
  });

  testWidgets('image preview is shown but sending requires confirmation', (
    tester,
  ) async {
    await mount(tester);
    const url = 'http://127.0.0.1:12345/private.jpg';
    await open(tester, link('image', jsonEncode({'url': url})));
    expect(server.sent, isEmpty);
    expect(find.byType(MixinImage), findsOneWidget);
    final preview = tester.widget<MixinImage>(find.byType(MixinImage));
    expect((preview.image as NetworkImage).url, url);
    await tester.tap(find.byType(MixinCloseButton));
    await tester.pumpAndSettle();
    expect(server.sent, isEmpty);
    await open(tester, link('image', jsonEncode({'url': url})));
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(server.sent.single.memberName, #sendImageMessageByUrl);
    server.sent.clear();
    await open(
      tester,
      link('image', jsonEncode({'url': 'file:///private.jpg'})),
    );
    expect(Navigator.of(context).canPop(), isFalse);
    expect(server.sent, isEmpty);
  });

  testWidgets('current recipient stays fixed and explicit action still sends', (
    tester,
  ) async {
    await mount(tester);
    await open(tester, link('text', 'current', user: false));
    expect(server.sent, isEmpty);
    (container.read(conversationProvider.notifier) as _ConversationState)
        .clear();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(server.sent.single.namedArguments[#recipientId], _user);
    await open(tester, link('text', 'action'), explicit: true);
    expect(server.sent, hasLength(2));
  });

  testWidgets('confirmation cannot send from a replacement account', (
    tester,
  ) async {
    await mount(tester);
    await open(tester, link('text', 'hello'));
    final replacement = _Server();
    (container.read(accountServerProvider.notifier) as _ServerState).replace(
      replacement,
    );
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(server.sent, isEmpty);
    expect(replacement.sent, isEmpty);
  });

  testWidgets(
    'group start remains Signal when its owner has an encrypted app',
    (tester) async {
      await database.mixinDatabase
          .into(database.mixinDatabase.apps)
          .insert(
            const App(
              appId: _user,
              appNumber: '7001',
              homeUri: '',
              redirectUri: '',
              name: 'App',
              iconUrl: '',
              description: '',
              appSecret: '',
              creatorId: _self,
              capabilities: 'ENCRYPTED',
            ),
          );
      const group = '00000000-0000-4000-8000-000000000004';
      await database.mixinDatabase
          .into(database.mixinDatabase.conversations)
          .insert(
            Conversation(
              conversationId: group,
              ownerId: _user,
              name: 'Group',
              category: sdk.ConversationCategory.group,
              createdAt: DateTime(2026),
              status: sdk.ConversationStatus.success,
            ),
          );
      await mount(tester);
      await open(tester, 'mixin://conversations/$group?start=hello');
      expect(server.sent, isEmpty);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(server.sent.single.positionalArguments[1], EncryptCategory.signal);
    },
  );

  testWidgets(
    'start uses confirmation and conversation encryption; lock blocks send',
    (tester) async {
      await mount(tester);
      await open(tester, 'mixin://conversations/$_conversation?start=hello');
      expect(server.sent, isEmpty);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(server.sent.single.positionalArguments[1], EncryptCategory.signal);
      await open(tester, link('text', 'locked'));
      container.read(appLockedProvider.notifier).state = true;
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(server.sent, hasLength(1));
      await tester.tap(find.byType(MixinCloseButton));
      await tester.pumpAndSettle();
      await open(tester, link('text', 'locked'));
      expect(Navigator.of(context).canPop(), isFalse);
    },
  );
}
