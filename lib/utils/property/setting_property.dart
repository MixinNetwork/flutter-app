import 'dart:convert';

import 'package:mixin_logger/mixin_logger.dart';

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

  AiProviderConfig? get selectedAiProvider {
    final providers = aiProviders.where((element) => element.enabled).toList();
    if (providers.isEmpty) {
      return null;
    }
    final selectedId = selectedAiProviderId;
    if (selectedId == null) {
      return providers.first;
    }
    return providers.firstWhereOrNull((element) => element.id == selectedId) ??
        providers.first;
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
  }
}
