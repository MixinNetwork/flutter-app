@TestOn('linux || mac-os')
library;

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
  '😀😃😄😁😆😅😂🤣😊😇',
  '👨‍👨‍👧‍👧👩‍👩‍👦👩‍👩‍👧👩‍👩‍👧‍👧👨‍👨‍👧👨‍👧‍👦',
  '北京欢迎你',
  '北京欢迎朋友你来',
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

  Future<List<int>> searchWithOption(String keyword,
      {bool tokenize = true}) async {
    final k = keyword.escapeFts5(tokenize: tokenize);
    const query = 'SELECT rowid FROM messages_fts WHERE messages_fts MATCH ?1';
    final row = await database.customSelect(
      query,
      variables: [Variable(k)],
    ).get();
    return row.map((e) => e.read<int>('rowid')).toList();
  }

  test('fts5 search with tokenize', () async {
    Future<List<int>> search(String keyword) => searchWithOption(keyword);

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
    expect(ret7, [2]);

    expect(await search('github com'), [2, 4, 8]);

    final ret8 = await search('0xbc314bfa1e99fe0055a98105c6aff467');
    expect(ret8, [9]);

    final ret9 = await search('😁');
    expect(ret9, [10]);

    expect(await search('😇'), [10]);

    expect(await search('👨‍👨‍👧‍'), [11]);

    expect(await search('北京欢迎'), [12, 13]);

    expect(await search('北京欢迎你'), [12, 13]);
  }, testOn: 'mac-os');

  test('fts5 search without tokenize', () async {
    Future<List<int>> search(String keyword) =>
        searchWithOption(keyword, tokenize: false);

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
    expect(ret7, [2]);

    expect(await search('github com'), [2, 4, 8]);

    final ret8 = await search('0xbc314bfa1e99fe0055a98105c6aff467');
    expect(ret8, [9]);

    final ret9 = await search('😁');
    expect(ret9, [10]);

    expect(await search('😇'), [10]);

    expect(await search('👨‍👨‍👧‍'), [11]);

    expect(await search('北京欢迎'), [12, 13]);

    expect(await search('北京欢迎你'), [12]);
  });
}
