import 'dart:ui';

import '../../../utils/hive_key_values.dart';

class SettingKeyValue extends HiveKeyValue {
  SettingKeyValue._() : super('setting');
  static const kKeyBrightness = 'Brightness';

  static SettingKeyValue? _instance;

  static SettingKeyValue get instance {
    _instance ??= SettingKeyValue._();
    return _instance!;
  }

  Brightness? get brightness {
    assert(box.isOpen);
    final int? index = box.get(kKeyBrightness);
    assert(const {0, 1, null}.contains(index));
    if (index == null) {
      return null;
    }
    return Brightness.values[index];
  }

  set brightness(Brightness? value) {
    assert(box.isOpen);
    box.put(kKeyBrightness, value?.index);
  }
}
