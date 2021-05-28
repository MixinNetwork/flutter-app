import 'dart:ui';

import '../ui/setting/bloc/setting_key_value.dart';
import 'simple_cubit.dart';
import 'subscribe_mixin.dart';

class BrightnessCubit extends SimpleCubit<Brightness?> with SubscribeMixin {
  BrightnessCubit() : super(SettingKeyValue.instance.brightness) {
    addSubscription(stream.listen((event) {
      SettingKeyValue.instance.brightness = event;
    }));
  }
}
