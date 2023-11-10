import 'dart:convert';

import 'package:mixin_logger/mixin_logger.dart';

import '../../db/dao/property_dao.dart';
import '../../enum/property_group.dart';
import '../db/property_storage.dart';
import '../extension/extension.dart';
import '../proxy.dart';

const _kEnableProxyKey = 'enable_proxy';
const _kSelectedProxyKey = 'selected_proxy';
const _kProxyListKey = 'proxy_list';

class SettingPropertyStorage extends PropertyStorage {
  SettingPropertyStorage(PropertyDao dao) : super(UserPropertyGroup.setting, dao);

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
}
