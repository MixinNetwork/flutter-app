import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

const _testFts5Content = [
  'test1',
  'github.com',
  'flutter_app',
  'github中文.com',
  '中文文案',
  'gitlab.com',
  'hello_[]()/*_star_*',
  'github.foo.com',
  '0xbc314bfa1e99fe0055a98105c6aff467',
];

void main() {
  final database = FtsDatabase(NativeDatabase.memory());

  setUpAll(() async {
    for (final content in _testFts5Content) {
      await database
          .into(database.messagesFts)
          .insert(MessagesFt(content: content.joinWhiteSpace()));
    }
  });

  test('fts5 search', () async {
    Future<List<int>> search(String keyword) async {
      final k = keyword.escapeFts5();
      const query =
          'SELECT rowid FROM messages_fts WHERE messages_fts MATCH ?1';
      final row = await database.customSelect(
        query,
        variables: [Variable(k)],
      ).get();
      return row.map((e) => e.read<int>('rowid')).toList();
    }

    final ret = await search('github');
    expect(ret, [2, 4, 8]);

    final ret2 = await search('中文');
    expect(ret2, [4, 5]);

    final ret3 = await search('github中文');
    expect(ret3, [4]);

    final ret4 = await search('github中文.com');
    expect(ret4, [4]);

    final ret5 = await search('git');
    expect(ret5, [2, 4, 6, 8]);

    final ret6 = await search('hello_[]()');
    expect(ret6, [7]);

    final ret7 = await search('github.com');
    expect(ret7, [2, 4, 8]);

    final ret8 = await search('0xbc314bfa1e99fe0055a98105c6aff467');
    expect(ret8, [9]);
  });
}
