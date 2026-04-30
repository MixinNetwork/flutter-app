import 'dart:convert';

import 'package:mixin_logger/mixin_logger.dart';

import '../../ai/model/ai_prompt_template.dart';
import '../../ai/model/ai_provider_config.dart';
import '../../db/dao/property_dao.dart';
import '../../db/util/property_storage.dart';
import '../../enum/property_group.dart';
import '../extension/extension.dart';
import '../proxy.dart';

const _kEnableProxyKey = 'enable_proxy';
const _kSelectedProxyKey = 'selected_proxy';
const _kProxyListKey = 'proxy_list';
const _kAiProviderListKey = 'ai_provider_list';
const _kSelectedAiProviderKey = 'selected_ai_provider';
const _kSelectedAiTranslatorProviderKey = 'selected_ai_translator_provider';
const _kSelectedAiTranslatorModelKey = 'selected_ai_translator_model';
const _kAiPromptTemplateOverridesKey = 'ai_prompt_template_overrides';

class SettingPropertyStorage extends PropertyStorage {
  SettingPropertyStorage(PropertyDao dao) : super(PropertyGroup.setting, dao);

  bool get enableProxy => get(_kEnableProxyKey) ?? false;

  set enableProxy(bool value) => set(_kEnableProxyKey, value);

  String? get selectedProxyId => get(_kSelectedProxyKey);

  set selectedProxyId(String? value) => set(_kSelectedProxyKey, value);

  List<ProxyConfig> get proxyList {
    final json = get<String>(_kProxyListKey);
    if (json == null || json.isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(json) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(ProxyConfig.fromJson)
          .toList();
    } catch (error, stacktrace) {
      e('load proxyList error: $error, $stacktrace');
    }
    return [];
  }

  ProxyConfig? get activatedProxy {
    if (!enableProxy) {
      return null;
    }
    final list = proxyList;
    if (list.isEmpty) {
      return null;
    }
    if (selectedProxyId == null) {
      return list.first;
    }
    return list.firstWhereOrNull((element) => element.id == selectedProxyId);
  }

  void addProxy(ProxyConfig config) {
    final list = [...proxyList, config];
    set(_kProxyListKey, jsonEncode(list));
  }

  void removeProxy(String id) {
    final list = proxyList.where((element) => element.id != id).toList();
    set(_kProxyListKey, jsonEncode(list));
  }

  List<AiProviderConfig> get aiProviders {
    final json = get<String>(_kAiProviderListKey);
    if (json == null || json.isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(json) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(AiProviderConfig.fromJson)
          .toList();
    } catch (error, stacktrace) {
      e('load aiProviders error: $error, $stacktrace');
    }
    return [];
  }

  String? get selectedAiProviderId => get(_kSelectedAiProviderKey);

  set selectedAiProviderId(String? value) =>
      set(_kSelectedAiProviderKey, value);

  String? get selectedAiTranslatorProviderId =>
      get(_kSelectedAiTranslatorProviderKey);

  set selectedAiTranslatorProviderId(String? value) =>
      set(_kSelectedAiTranslatorProviderKey, value);

  String? get selectedAiTranslatorModel => get(_kSelectedAiTranslatorModelKey);

  set selectedAiTranslatorModel(String? value) =>
      set(_kSelectedAiTranslatorModelKey, value);

  AiProviderConfig? get selectedAiProvider =>
      _resolveAiProvider(selectedAiProviderId, null);

  AiProviderConfig? get selectedAiTranslatorProvider =>
      _resolveAiProvider(
        selectedAiTranslatorProviderId,
        selectedAiTranslatorModel,
      ) ??
      selectedAiProvider;

  AiProviderConfig? _resolveAiProvider(String? selectedId, String? model) {
    final providers = aiProviders.where((element) => element.enabled).toList();
    if (providers.isEmpty) {
      return null;
    }
    final provider = selectedId == null
        ? providers.first
        : providers.firstWhereOrNull((element) => element.id == selectedId) ??
              providers.first;
    final selectedModel = model?.trim();
    if (selectedModel == null || selectedModel.isEmpty) return provider;
    if (!provider.models.contains(selectedModel)) return provider;
    if (provider.model == selectedModel) return provider;
    return provider.copyWith(model: selectedModel, defaultModel: selectedModel);
  }

  void saveAiProvider(AiProviderConfig config) {
    final providers = aiProviders;
    final index = providers.indexWhere((element) => element.id == config.id);
    if (index >= 0) {
      providers[index] = config;
    } else {
      providers.add(config);
    }
    set(
      _kAiProviderListKey,
      jsonEncode(providers.map((element) => element.toJson()).toList()),
    );
    selectedAiProviderId ??= config.id;
  }

  void removeAiProvider(String id) {
    final providers = aiProviders.where((element) => element.id != id).toList();
    set(
      _kAiProviderListKey,
      jsonEncode(providers.map((element) => element.toJson()).toList()),
    );
    if (selectedAiProviderId == id) {
      selectedAiProviderId = providers.firstOrNull?.id;
    }
    if (selectedAiTranslatorProviderId == id) {
      selectedAiTranslatorProviderId = null;
      selectedAiTranslatorModel = null;
    }
  }

  Map<String, String> get _aiPromptTemplateOverrides {
    final json = get<String>(_kAiPromptTemplateOverridesKey);
    if (json == null || json.isEmpty) {
      return {};
    }
    try {
      final map = jsonDecode(json) as Map;
      return map.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    } catch (error, stacktrace) {
      e('load aiPromptTemplateOverrides error: $error, $stacktrace');
      return {};
    }
  }

  String aiPromptTemplate(AiPromptTemplateKey key) {
    final overrides = _aiPromptTemplateOverrides;
    if (overrides.containsKey(key.storageKey)) {
      return overrides[key.storageKey] ?? '';
    }
    return key.definition.defaultValue;
  }

  bool hasAiPromptTemplateOverride(AiPromptTemplateKey key) =>
      _aiPromptTemplateOverrides.containsKey(key.storageKey);

  void saveAiPromptTemplate(AiPromptTemplateKey key, String value) {
    final overrides = _aiPromptTemplateOverrides;
    overrides[key.storageKey] = value;
    set(_kAiPromptTemplateOverridesKey, jsonEncode(overrides));
  }

  void resetAiPromptTemplate(AiPromptTemplateKey key) {
    final overrides = _aiPromptTemplateOverrides..remove(key.storageKey);
    set(_kAiPromptTemplateOverridesKey, jsonEncode(overrides));
  }
}
