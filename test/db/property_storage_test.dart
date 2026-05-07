@TestOn('linux || mac-os')
library;

import 'package:drift/native.dart';
import 'package:flutter_app/ai/model/ai_prompt_template.dart';
import 'package:flutter_app/ai/model/ai_provider_config.dart';
import 'package:flutter_app/ai/model/ai_provider_type.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/db/util/property_storage.dart';
import 'package:flutter_app/enum/property_group.dart';
import 'package:flutter_app/utils/property/setting_property.dart';
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

  test('AI prompt template settings support override and reset', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final storage = SettingPropertyStorage(database.propertyDao);
    const key = AiPromptTemplateKey.chatSystem;

    expect(storage.aiPromptTemplate(key), key.definition.defaultValue);
    expect(storage.hasAiPromptTemplateOverride(key), isFalse);

    storage.saveAiPromptTemplate(key, 'Custom prompt {{conversationId}}');
    expect(storage.aiPromptTemplate(key), 'Custom prompt {{conversationId}}');
    expect(storage.hasAiPromptTemplateOverride(key), isTrue);

    storage.saveAiPromptTemplate(key, '');
    expect(storage.aiPromptTemplate(key), isEmpty);
    expect(storage.hasAiPromptTemplateOverride(key), isTrue);

    storage.resetAiPromptTemplate(key);
    expect(storage.aiPromptTemplate(key), key.definition.defaultValue);
    expect(storage.hasAiPromptTemplateOverride(key), isFalse);
  });

  test('AI translator provider can use an independent model', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final storage = SettingPropertyStorage(database.propertyDao);
    final defaultProvider = AiProviderConfig(
      id: 'default',
      name: 'Default',
      type: AiProviderType.openaiCompatible,
      baseUrl: 'https://api.example.com/v1',
      apiKey: 'key',
      model: 'chat-model',
      models: const ['chat-model', 'translate-model'],
      defaultModel: 'chat-model',
    );
    final translatorProvider = AiProviderConfig(
      id: 'translator',
      name: 'Translator',
      type: AiProviderType.openaiCompatible,
      baseUrl: 'https://api.example.com/v1',
      apiKey: 'key',
      model: 'small',
      models: const ['small', 'large'],
      defaultModel: 'small',
    );

    storage
      ..saveAiProvider(defaultProvider)
      ..saveAiProvider(translatorProvider)
      ..selectedAiProviderId = defaultProvider.id;

    expect(storage.selectedAiProvider?.id, defaultProvider.id);
    expect(storage.selectedAiProvider?.model, 'chat-model');
    expect(storage.selectedAiTranslatorProvider?.id, defaultProvider.id);
    expect(storage.selectedAiTranslatorProvider?.model, 'chat-model');

    storage
      ..selectedAiTranslatorProviderId = translatorProvider.id
      ..selectedAiTranslatorModel = 'large';

    expect(storage.selectedAiProvider?.id, defaultProvider.id);
    expect(storage.selectedAiProvider?.model, 'chat-model');
    expect(storage.selectedAiTranslatorProvider?.id, translatorProvider.id);
    expect(storage.selectedAiTranslatorProvider?.model, 'large');
  });
}
