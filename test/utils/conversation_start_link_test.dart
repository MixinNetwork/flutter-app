@TestOn('linux || mac-os')
library;

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/core/conversation/conversation_list_store.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/enum/encrypt_category.dart';
import 'package:flutter_app/ui/provider/account_server_provider.dart';
import 'package:flutter_app/ui/provider/conversation_provider.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus, UserRelationship;

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
}

Future<BuildContext> _pumpApp(
  WidgetTester tester,
  _FakeAccountServer accountServer,
) async {
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
      child: MaterialApp(
        home: Consumer(
          builder: (c, ref, _) {
            ref
              ..watch(databaseProvider)
              ..watch(accountServerProvider)
              ..watch(conversationProvider);
            context = c;
            return const SizedBox();
          },
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
  for (var i = 0; i < 100 && accountServer.sent.length < sends; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
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
