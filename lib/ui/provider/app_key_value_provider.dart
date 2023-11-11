import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/db/app_setting_key_value.dart';
import 'database_provider.dart';

final settingKeyValueProvider = ChangeNotifierProvider<AppSettingKeyValue>(
    (ref) => ref.watch(appDatabaseProvider).settingKeyValue);
