import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

const _testFts5Content = {
  '1': 'test1',
  '2': 'github.com',
  '3': 'flutter_app',
  '4': 'github中文.com',
  '5': '中文文案',
  '6': 'gitlab.com',
  '7': 'hello_[]()/*_star_*',
};

void main() {
  final mixinDatabase = MixinDatabase(NativeDatabase.memory());

  setUpAll(() async {
    final conversationId = const Uuid().v4();
    final userId = const Uuid().v4();

    for (final entry in _testFts5Content.entries) {
      await mixinDatabase.messageDao.insertFts(
        entry.key,
        conversationId,
        entry.value.joinWhiteSpace(),
        DateTime.now(),
        userId,
      );
    }
  });

  test('fts5 search', () async {
    Future<List<String>> search(String keyword) async {
      final k = keyword.escapeFts5();
      const query =
          'SELECT message_id FROM messages_fts WHERE messages_fts MATCH ?1';
      final row = await mixinDatabase.customSelect(
        query,
        variables: [Variable(k)],
      ).get();
      return row.map((e) => e.read<String>('message_id')).toList();
    }

    final ret = await search('github');
    expect(ret, ['2', '4']);

    final ret2 = await search('中文');
    expect(ret2, ['4', '5']);

    final ret3 = await search('github中文');
    expect(ret3, ['4']);

    final ret4 = await search('github中文.com');
    expect(ret4, ['4']);

    final ret5 = await search('git');
    expect(ret5, ['2', '4', '6']);

    final ret6 = await search('hello_[]()');
    expect(ret6, ['7']);
  });
}
