@TestOn('linux || mac-os')
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_app/db/app/app_database.dart';
import 'package:flutter_app/enum/property_group.dart';
import 'package:flutter_app/utils/db/lazy_db_key_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tet key value', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final storage = BaseAppKeyValue(
      group: AppPropertyGroup.setting,
      dao: database.appKeyValueDao,
    );

    await storage.initialized;

    expect(storage.get<bool>('test_empty'), null);
    unawaited(storage.set('test_empty', false));
    expect(storage.get<int>('test_empty'), null);
    expect(storage.get<double>('test_empty'), null);
    expect(storage.get<String>('test_empty'), 'false');
    expect(storage.getList('test_empty'), null);
    expect(storage.getMap('test_empty'), null);

    unawaited(storage.set('test_int', 12345));
    expect(storage.get<int>('test_int'), 12345);
    unawaited(storage.set('test_int', null));
    expect(storage.get<int>('test_int'), null);

    expect(storage.get<String>('test_string'), null);
    unawaited(storage.set('test_string', '12345'));
    expect(storage.get<String>('test_string'), '12345');

    unawaited(storage.set('test_bool', true));
    expect(storage.get<bool>('test_bool'), true);
    unawaited(storage.set('test_bool', false));
    expect(storage.get<bool>('test_bool'), false);

    unawaited(storage.set('test_double', 12345.6789));
    expect(storage.get<double>('test_double'), 12345.6789);
    expect(storage.get('test_double'), '12345.6789');
    expect(storage.get<List>('test_double'), null);
    expect(storage.get<int>('test_double'), null);

    unawaited(storage.set('test_map', {'a': 1, 'b': 2}));
    expect(storage.getMap<String, dynamic>('test_map'), {'a': 1, 'b': 2});
    expect(storage.getMap('test_map'), {'a': 1, 'b': 2});

    unawaited(storage.set('test_list', [1, 2, 3]));
    expect(storage.getList<dynamic>('test_list'), [1, 2, 3]);
    expect(storage.getList<int>('test_list'), [1, 2, 3]);

    unawaited(storage.set('test_list_string', ['1', '2', '3']));
    expect(storage.getList<String>('test_list_string'), ['1', '2', '3']);
    expect(storage.getList('test_list_string'), ['1', '2', '3']);
  });
}
