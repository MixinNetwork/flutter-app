import '../../db/dao/property_dao.dart';
import '../../db/util/property_storage.dart';
import '../../enum/property_group.dart';
import '../extension/extension.dart';

const _kEnableProxyKey = 'enable_proxy';
const _kSelectedProxyKey = 'selected_proxy';
const _kProxyListKey = 'proxy_list';

class SettingPropertyStorage extends PropertyStorage {
  SettingPropertyStorage(PropertyDao dao) : super(PropertyGroup.setting, dao);

  bool get enableProxy => get(_kEnableProxyKey) ?? false;

  set enableProxy(bool value) => set(_kEnableProxyKey, value);

  int get selectedProxy => get(_kSelectedProxyKey) ?? 0;

  set selectedProxy(int value) => set(_kSelectedProxyKey, value);

  List<String> get proxyList => getList(_kProxyListKey) ?? [];

  String? get activatedProxyUrl {
    if (!enableProxy) {
      return null;
    }
    final list = proxyList;
    if (list.isEmpty) {
      return null;
    }
    return list.getOrNull(selectedProxy) ?? list.first;
  }

  void addProxy(String proxyUrl) {
    final list = proxyList;
    if (list.contains(proxyUrl)) {
      return;
    }
    list.add(proxyUrl);
    notifyListeners();
    set(_kProxyListKey, list);
  }

  void removeProxy(String proxy) {
    final list = proxyList..remove(proxy);
    notifyListeners();
    set(_kProxyListKey, list);
  }
}
