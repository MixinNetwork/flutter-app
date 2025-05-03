@TestOn('linux || mac-os')
library;

import 'package:drift/native.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/db/util/property_storage.dart';
import 'package:flutter_app/enum/property_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tet PropertyStorage', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final storage = PropertyStorage(
      PropertyGroup.setting,
      database.propertyDao,
    );

    expect(storage.get<bool>('test_empty'), null);
    storage.set('test_empty', false);
    expect(storage.get<int>('test_empty'), null);
    expect(storage.get<double>('test_empty'), null);
    expect(storage.get<String>('test_empty'), 'false');
    expect(storage.getList('test_empty'), null);
    expect(storage.getMap('test_empty'), null);

    storage.set('test_int', 12345);
    expect(storage.get<int>('test_int'), 12345);
    storage.set('test_int', null);
    expect(storage.get<int>('test_int'), null);

    expect(storage.get<String>('test_string'), null);
    storage.set('test_string', '12345');
    expect(storage.get<String>('test_string'), '12345');

    storage.set('test_bool', true);
    expect(storage.get<bool>('test_bool'), true);
    storage.set('test_bool', false);
    expect(storage.get<bool>('test_bool'), false);

    storage.set('test_double', 12345.6789);
    expect(storage.get<double>('test_double'), 12345.6789);
    expect(storage.get('test_double'), '12345.6789');
    expect(storage.get<List>('test_double'), null);
    expect(storage.get<int>('test_double'), null);

    storage.set('test_map', {'a': 1, 'b': 2});
    expect(storage.getMap<String, dynamic>('test_map'), {'a': 1, 'b': 2});
    expect(storage.getMap('test_map'), {'a': 1, 'b': 2});

    storage.set('test_list', [1, 2, 3]);
    expect(storage.getList<dynamic>('test_list'), [1, 2, 3]);
    expect(storage.getList<int>('test_list'), [1, 2, 3]);

    storage.set('test_list_string', ['1', '2', '3']);
    expect(storage.getList<String>('test_list_string'), ['1', '2', '3']);
    expect(storage.getList('test_list_string'), ['1', '2', '3']);
  });
}
