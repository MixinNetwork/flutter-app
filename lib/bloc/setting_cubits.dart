import 'dart:ui';

import 'package:hydrated_bloc/hydrated_bloc.dart';

class BrightnessCubit extends HydratedCubit<Brightness?> {
  BrightnessCubit() : super(null);

  static const _kKeyBrightness = 'Brightness';

  @override
  Brightness? fromJson(Map<String, dynamic> json) {
    final int? index = json[_kKeyBrightness];
    assert(const {0, 1, null}.contains(index), 'invalid brightness value.');
    if (index == null) {
      return null;
    }
    return Brightness.values[index];
  }

  @override
  Map<String, dynamic>? toJson(Brightness? state) =>
      {_kKeyBrightness: state?.index};
}
