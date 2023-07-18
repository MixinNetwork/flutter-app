import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../utils/logger.dart';

class SettingState extends Equatable {
  const SettingState({
    int? brightness,
    bool? messageShowAvatar,
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
    bool? collapsedSidebar,
    double? chatFontSizeDelta,
  })  : _brightness = brightness,
        _messageShowAvatar = messageShowAvatar,
        _messagePreview = messagePreview,
        _photoAutoDownload = photoAutoDownload,
        _videoAutoDownload = videoAutoDownload,
        _fileAutoDownload = fileAutoDownload,
        _collapsedSidebar = collapsedSidebar,
        _chatFontSizeDelta = chatFontSizeDelta;

  factory SettingState.fromMap(Map<String, dynamic> map) => SettingState(
        brightness: map['brightness'] as int?,
        messageShowAvatar: map['messageShowAvatar'] as bool?,
        messagePreview: map['messagePreview'] as bool?,
        photoAutoDownload: map['photoAutoDownload'] as bool?,
        videoAutoDownload: map['videoAutoDownload'] as bool?,
        fileAutoDownload: map['fileAutoDownload'] as bool?,
        collapsedSidebar: map['collapsedSidebar'] as bool?,
        chatFontSizeDelta: map['chatFontSizeDelta'] as double?,
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
  final int? _brightness;
  final bool? _messageShowAvatar;
  final bool? _messagePreview;
  final bool? _photoAutoDownload;
  final bool? _videoAutoDownload;
  final bool? _fileAutoDownload;
  final bool? _collapsedSidebar;
  final double? _chatFontSizeDelta;

  int get brightness => _brightness ?? 0;

  bool get messageShowAvatar => _messageShowAvatar ?? false;

  bool get messagePreview => _messagePreview ?? true;

  bool get photoAutoDownload => _photoAutoDownload ?? true;

  bool get videoAutoDownload => _videoAutoDownload ?? true;

  bool get fileAutoDownload => _fileAutoDownload ?? true;

  bool get collapsedSidebar => _collapsedSidebar ?? false;

  double get chatFontSizeDelta => _chatFontSizeDelta ?? 0;

  @override
  List<Object?> get props => [
        _brightness,
        _messageShowAvatar,
        _messagePreview,
        _photoAutoDownload,
        _videoAutoDownload,
        _fileAutoDownload,
        _collapsedSidebar,
        _chatFontSizeDelta,
      ];

  Map<String, dynamic> toMap() => {
        'brightness': _brightness,
        'messageShowAvatar': _messageShowAvatar,
        'messagePreview': _messagePreview,
        'photoAutoDownload': _photoAutoDownload,
        'videoAutoDownload': _videoAutoDownload,
        'fileAutoDownload': _fileAutoDownload,
        'collapsedSidebar': _collapsedSidebar,
        'chatFontSizeDelta': _chatFontSizeDelta,
      };

  SettingState copyWith({
    int? brightness,
    bool? messageShowAvatar,
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
    bool? collapsedSidebar,
    double? chatFontSizeDelta,
  }) =>
      SettingState(
        brightness: brightness ?? _brightness,
        messageShowAvatar: messageShowAvatar ?? _messageShowAvatar,
        messagePreview: messagePreview ?? _messagePreview,
        photoAutoDownload: photoAutoDownload ?? _photoAutoDownload,
        videoAutoDownload: videoAutoDownload ?? _videoAutoDownload,
        fileAutoDownload: fileAutoDownload ?? _fileAutoDownload,
        collapsedSidebar: collapsedSidebar ?? _collapsedSidebar,
        chatFontSizeDelta: chatFontSizeDelta ?? _chatFontSizeDelta,
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
    switch (state._brightness) {
      case 0:
      case null:
        return null;
      case 1:
        return Brightness.dark;
      case 2:
        return Brightness.light;
      default:
        w('invalid value for brightness. $state');
        return null;
    }
  }

  ThemeMode get themeMode {
    switch (brightness) {
      case Brightness.dark:
        return ThemeMode.dark;
      case Brightness.light:
        return ThemeMode.light;
      case null:
        return ThemeMode.system;
    }
  }

  set messageShowAvatar(bool? value) =>
      emit(state.copyWith(messageShowAvatar: value));

  set messagePreview(bool? value) =>
      emit(state.copyWith(messagePreview: value));

  set photoAutoDownload(bool? value) =>
      emit(state.copyWith(photoAutoDownload: value));

  set videoAutoDownload(bool? value) =>
      emit(state.copyWith(videoAutoDownload: value));

  set fileAutoDownload(bool? value) =>
      emit(state.copyWith(fileAutoDownload: value));

  set collapsedSidebar(bool? value) =>
      emit(state.copyWith(collapsedSidebar: value));

  set chatFontSizeDelta(double? value) =>
      emit(state.copyWith(chatFontSizeDelta: value));

  void migrate({
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
    bool? collapsedSidebar,
  }) {
    if (messagePreview == null &&
        photoAutoDownload == null &&
        videoAutoDownload == null &&
        fileAutoDownload == null &&
        collapsedSidebar == null) return;

    emit(state.copyWith(
      messagePreview: messagePreview,
      photoAutoDownload: photoAutoDownload,
      videoAutoDownload: videoAutoDownload,
      fileAutoDownload: fileAutoDownload,
      collapsedSidebar: collapsedSidebar,
    ));
  }

  @override
  SettingState fromJson(Map<String, dynamic> json) =>
      SettingState.fromMap(json);

  @override
  Map<String, dynamic> toJson(SettingState state) => state.toMap();
}
