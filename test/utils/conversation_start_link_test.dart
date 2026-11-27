@TestOn('linux || mac-os')
library;

import 'dart:async';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value;
import 'package:drift/native.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/core/conversation/conversation_list_store.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/enum/encrypt_category.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/provider/account_server_provider.dart';
import 'package:flutter_app/ui/provider/conversation_provider.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus, UserRelationship;
import 'package:overlay_support/overlay_support.dart';

const _me = '00000000-0000-4000-8000-000000000001';
const _owner = '00000000-0000-4000-8000-000000000002';
const _conversationId = '00000000-0000-4000-8000-000000000003';

void main() {
  const bot = '7000100001';
  const encrypted = '["ENCRYPTED"]';
  for (final (name, category, identityNumber, capabilities, expected) in [
    (
      'a contact',
      ConversationCategory.contact,
      '1234',
      null,
      EncryptCategory.signal,
    ),
    (
      'a plain bot',
      ConversationCategory.contact,
      bot,
      '[]',
      EncryptCategory.plain,
    ),
    (
      'an encrypted bot',
      ConversationCategory.contact,
      bot,
      encrypted,
      EncryptCategory.encrypted,
    ),
    (
      'a bot whose app is not stored yet',
      ConversationCategory.contact,
      bot,
      null,
      EncryptCategory.plain,
    ),
    (
      'a group that an encrypted bot owns',
      ConversationCategory.group,
      bot,
      encrypted,
      EncryptCategory.signal,
    ),
  ]) {
    testWidgets('a start link to $name keeps its encryption', (tester) async {
      final mixinDatabase = MixinDatabase(NativeDatabase.memory());
      await tester.runAsync(
        () => _insert(mixinDatabase, category, identityNumber, capabilities),
      );
      final accountServer = _FakeAccountServer(_FakeDatabase(mixinDatabase));
      final context = await _pumpApp(tester, accountServer);

      await _openStartLink(tester, context, accountServer, 1);

      expect(accountServer.sent, [('hi', expected)]);

      await _dispose(tester, mixinDatabase);
    });
  }

  testWidgets('a start link to the open chat uses the app of now', (
    tester,
  ) async {
    final mixinDatabase = MixinDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => _insert(mixinDatabase, ConversationCategory.contact, bot, '[]'),
    );
    final accountServer = _FakeAccountServer(_FakeDatabase(mixinDatabase));
    final context = await _pumpApp(tester, accountServer);
    await _openStartLink(tester, context, accountServer, 1);

    await tester.runAsync(
      () => mixinDatabase
          .update(mixinDatabase.apps)
          .write(const AppsCompanion(capabilities: Value(encrypted))),
    );
    await _openStartLink(tester, context, accountServer, 2);

    expect(accountServer.sent, [
      ('hi', EncryptCategory.plain),
      ('hi', EncryptCategory.encrypted),
    ]);
    await _dispose(tester, mixinDatabase);
  });

  testWidgets('a confirmed start link uses the app of the time of the send', (
    tester,
  ) async {
    final mixinDatabase = MixinDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => _insert(mixinDatabase, ConversationCategory.contact, bot, '[]'),
    );
    final accountServer = _FakeAccountServer(_FakeDatabase(mixinDatabase));
    final context = await _pumpApp(tester, accountServer);
    final send = find.text(Localization.current.send);

    unawaited(
      openUri(
        context,
        'mixin://conversations/$_conversationId?start=hi',
        confirmSend: true,
      ),
    );
    await _pumpUntil(tester, () => send.evaluate().isNotEmpty);
    await tester.pumpAndSettle();
    expect(accountServer.sent, isEmpty);

    // The app changes while the dialog is open.
    await tester.runAsync(
      () => mixinDatabase
          .update(mixinDatabase.apps)
          .write(const AppsCompanion(capabilities: Value(encrypted))),
    );
    await tester.tap(send);
    await _pumpUntil(tester, () => accountServer.sent.isNotEmpty);

    expect(accountServer.sent, [('hi', EncryptCategory.encrypted)]);
    await _dispose(tester, mixinDatabase);
  });

  testWidgets('a start link sends after the tapped message is gone', (
    tester,
  ) async {
    final mixinDatabase = MixinDatabase(
      NativeDatabase.memory().interceptWith(_SlowReads()),
    );
    await tester.runAsync(
      () => _insert(mixinDatabase, ConversationCategory.contact, '1234', null),
    );
    final accountServer = _FakeAccountServer(_FakeDatabase(mixinDatabase));
    // The link is in another chat, which closes when this one opens.
    final context = await _pumpApp(tester, accountServer, inAnotherChat: true);

    await _openStartLink(tester, context, accountServer, 1);

    expect(context.mounted, isFalse);
    expect(accountServer.sent, [('hi', EncryptCategory.signal)]);
    await _dispose(tester, mixinDatabase);
  });

  testWidgets('a start link before the account is ready fails with a toast', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountServerProvider.overrideWith((ref) => AccountServerOpener()),
        ],
        child: OverlaySupport.global(
          child: BrightnessData(
            value: 0,
            brightnessThemeData: lightBrightnessThemeData,
            child: MaterialApp(
              localizationsDelegates: const [Localization.delegate],
              supportedLocales: Localization.delegate.supportedLocales,
              home: Builder(
                builder: (c) {
                  context = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );

    final opened = openUri(
      context,
      'mixin://conversations/$_conversationId?start=hi',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(await opened, isFalse);
    expect(find.textContaining('not ready'), findsOneWidget);
    // Ends the timers of the toast: its duration, then its fade out.
    for (var second = 0; second < 5; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
  });
}

Future<BuildContext> _pumpApp(
  WidgetTester tester,
  _FakeAccountServer accountServer, {
  bool inAnotherChat = false,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWith(
          (ref) => _ReadyDatabase(accountServer.database),
        ),
        accountServerProvider.overrideWith(
          (ref) => _ReadyAccountServer(accountServer),
        ),
      ],
      child: BrightnessData(
        value: 0,
        brightnessThemeData: lightBrightnessThemeData,
        child: MaterialApp(
          localizationsDelegates: const [Localization.delegate],
          supportedLocales: Localization.delegate.supportedLocales,
          home: Consumer(
            builder: (_, ref, _) {
              ref
                ..watch(databaseProvider)
                ..watch(accountServerProvider);
              final chat = ref.watch(conversationProvider);
              if (inAnotherChat && chat != null) return const SizedBox();
              return Builder(
                builder: (c) {
                  context = c;
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      ),
    ),
  );

  return context;
}

Future<void> _openStartLink(
  WidgetTester tester,
  BuildContext context,
  _FakeAccountServer accountServer,
  int sends,
) async {
  unawaited(
    openUri(context, 'mixin://conversations/$_conversationId?start=hi'),
  );
  await _pumpUntil(tester, () => accountServer.sent.length >= sends);
}

/// The database answers in real time.
Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A read takes more than a frame, as with the database isolate of the app.
class _SlowReads extends QueryInterceptor {
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.runSelect(executor, statement, args);
  }
}

Future<void> _dispose(WidgetTester tester, MixinDatabase database) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 11));
  await tester.runAsync(database.close);
}

Future<void> _insert(
  MixinDatabase database,
  ConversationCategory category,
  String identityNumber,
  String? capabilities,
) => database.batch((batch) {
  batch
    ..insert(
      database.users,
      User(
        userId: _owner,
        identityNumber: identityNumber,
        fullName: 'Owner',
        relationship: UserRelationship.friend,
        appId: capabilities == null ? null : _owner,
      ),
    )
    ..insert(
      database.conversations,
      Conversation(
        conversationId: _conversationId,
        ownerId: _owner,
        category: category,
        createdAt: DateTime(2026),
        status: ConversationStatus.success,
      ),
    );
  if (capabilities != null) {
    batch.insert(
      database.apps,
      AppsCompanion.insert(
        appId: _owner,
        appNumber: identityNumber,
        homeUri: '',
        redirectUri: '',
        name: 'Bot',
        iconUrl: '',
        description: '',
        appSecret: '',
        creatorId: _owner,
        capabilities: Value(capabilities),
      ),
    );
  }
});

class _ReadyDatabase extends DatabaseOpener {
  _ReadyDatabase(Database database) {
    state = AsyncValue.data(database);
  }

  @override
  Future<void> close() async {}
}

class _ReadyAccountServer extends AccountServerOpener {
  _ReadyAccountServer(AccountServer server) {
    state = AsyncValue.data(server);
  }
}

class _FakeDatabase implements Database {
  _FakeDatabase(this.mixinDatabase);

  @override
  final MixinDatabase mixinDatabase;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      switch (invocation.memberName) {
        #conversationDao => mixinDatabase.conversationDao,
        #appDao => mixinDatabase.appDao,
        #userDao => mixinDatabase.userDao,
        #participantDao => mixinDatabase.participantDao,
        _ => super.noSuchMethod(invocation),
      };
}

class _FakeAccountServer implements AccountServer {
  _FakeAccountServer(this.database);

  @override
  final Database database;

  final sent = <(String, EncryptCategory)>[];

  @override
  String get userId => _me;

  @override
  Future<void> selectConversation(String? conversationId) async {}

  @override
  final conversationListStore = _FakeConversationListStore();

  @override
  Future<void> sendTextMessage(
    String content,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
    bool silent = false,
  }) async => sent.add((content, encryptCategory));

  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConversationListStore implements ConversationListStore {
  @override
  Stream<ConversationListEvent> get events => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
