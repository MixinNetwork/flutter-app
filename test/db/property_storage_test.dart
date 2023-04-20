import 'package:drift/native.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/db/util/property_storage.dart';
import 'package:flutter_app/enum/property_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tet PropertyStorage', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final storage =
        PropertyStorage(PropertyGroup.setting, database.propertyDao);

    expect(await storage.get<bool>('test_empty'), null);
    await storage.set('test_empty', false);
    expect(await storage.get<int>('test_empty'), null);
    expect(await storage.get<double>('test_empty'), null);
    expect(await storage.get<String>('test_empty'), 'false');
    expect(await storage.getList('test_empty'), null);
    expect(await storage.getMap('test_empty'), null);

    await storage.set('test_int', 12345);
    expect(await storage.get<int>('test_int'), 12345);
    await storage.set('test_int', null);
    expect(await storage.get<int>('test_int'), null);

    expect(await storage.get<String>('test_string'), null);
    await storage.set('test_string', '12345');
    expect(await storage.get<String>('test_string'), '12345');

    await storage.set('test_bool', true);
    expect(await storage.get<bool>('test_bool'), true);
    await storage.set('test_bool', false);
    expect(await storage.get<bool>('test_bool'), false);

    await storage.set('test_double', 12345.6789);
    expect(await storage.get<double>('test_double'), 12345.6789);
    expect(await storage.get('test_double'), '12345.6789');
    expect(await storage.get<List>('test_double'), null);
    expect(await storage.get<int>('test_double'), null);

    await storage.set('test_map', {'a': 1, 'b': 2});
    expect(await storage.getMap<String, dynamic>('test_map'), {'a': 1, 'b': 2});
    expect(await storage.getMap('test_map'), {'a': 1, 'b': 2});

    await storage.set('test_list', [1, 2, 3]);
    expect(await storage.getList<dynamic>('test_list'), [1, 2, 3]);
    expect(await storage.getList<int>('test_list'), [1, 2, 3]);

    await storage.set('test_list_string', ['1', '2', '3']);
    expect(await storage.getList<String>('test_list_string'), ['1', '2', '3']);
    expect(await storage.getList('test_list_string'), ['1', '2', '3']);
  });
}
