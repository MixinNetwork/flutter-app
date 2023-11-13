import 'package:mixin_logger/mixin_logger.dart';

import '../../enum/property_group.dart';
import '../extension/extension.dart';
import '../proxy.dart';
import 'db_key_value.dart';

class AppSettingKeyValue extends BaseAppKeyValue {
  AppSettingKeyValue(KeyValueDao<AppPropertyGroup> dao)
      : super(group: AppPropertyGroup.setting, dao: dao);
}

const _kEnableProxyKey = 'enable_proxy';
const _kSelectedProxyKey = 'selected_proxy';
const _kProxyListKey = 'proxy_list';

extension SettingProxy on AppSettingKeyValue {
  bool get enableProxy => get(_kEnableProxyKey) ?? false;

  set enableProxy(bool value) => set(_kEnableProxyKey, value);

  String? get selectedProxyId => get(_kSelectedProxyKey);

  set selectedProxyId(String? value) => set(_kSelectedProxyKey, value);

  List<ProxyConfig> get proxyList {
    final list = get<List<Map<String, dynamic>>>(_kProxyListKey);
    if (list == null || list.isEmpty) {
      return [];
    }
    try {
      return list.map(ProxyConfig.fromJson).toList();
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
    set(_kProxyListKey, list);
  }

  void removeProxy(String id) {
    final list = proxyList.where((element) => element.id != id).toList();
    set(_kProxyListKey, list);
  }
}
