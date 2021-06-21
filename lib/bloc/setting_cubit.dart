import 'dart:io';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:provider/provider.dart';

class SettingState extends Equatable {
  const SettingState({this.brightness = 0});

  factory SettingState.fromMap(Map<String, dynamic> map) => SettingState(
        brightness: map['brightness'] as int,
      );

  /// The brightness of theme.
  /// 0 : follow system
  /// 1 : dark
  /// 2 : light
  ///
  /// The reason [int] instead of [Brightness] enum is that Hive has limited
  /// support for custom data class.
  /// https://docs.hivedb.dev/#/custom-objects/type_adapters?id=register-adapter
  /// https://github.com/hivedb/hive/issues/525
  /// https://github.com/hivedb/hive/issues/518
  final int brightness;

  @override
  List<Object?> get props => [brightness];

  Map<String, dynamic> toMap() => {
        'brightness': brightness,
      };

  SettingState copyWith({
    int? brightness,
  }) =>
      SettingState(
        brightness: brightness ?? this.brightness,
      );
}

class SettingCubit extends HydratedCubit<SettingState> {
  SettingCubit() : super(const SettingState());

  /// [brightness] null to follow system.
  set brightness(Brightness? value) {
    switch (value) {
      case Brightness.dark:
        emit(state.copyWith(brightness: 1));
        break;
      case Brightness.light:
        emit(state.copyWith(brightness: 2));
        break;
      case null:
        emit(state.copyWith(brightness: 0));
        break;
    }
  }

  Brightness? get brightness {
    switch (state.brightness) {
      case 0:
        return null;
      case 1:
        return Brightness.dark;
      case 2:
        return Brightness.light;
      default:
        assert(false, 'invalid value for brightness. $state');
        return null;
    }
  }

  @override
  SettingState fromJson(Map<String, dynamic> json) =>
      SettingState.fromMap(json);

  @override
  Map<String, dynamic> toJson(SettingState state) => state.toMap();
}

extension SameBrightness on BuildContext {
  bool get sameBrightness {
    if (!Platform.isMacOS) return false;
    final platformBrightness = MediaQuery.of(this).platformBrightness;
    return (watch<SettingCubit>().brightness ?? platformBrightness) ==
        platformBrightness;
  }
}
