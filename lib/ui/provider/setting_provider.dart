import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/hydration_codec.dart';
import '../../utils/hydration_storage.dart';
import '../../utils/logger.dart';

const _kSettingStorageKey = 'SettingCubit';

class SettingState extends Equatable {
  const SettingState({
    int? brightnessValue,
    bool? messageShowAvatar,
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
    bool? collapsedSidebar,
    double? chatFontSizeDelta,
    bool? messageShowIdentityNumber,
  }) : _brightnessValue = brightnessValue,
       _messageShowAvatar = messageShowAvatar,
       _messagePreview = messagePreview,
       _photoAutoDownload = photoAutoDownload,
       _videoAutoDownload = videoAutoDownload,
       _fileAutoDownload = fileAutoDownload,
       _collapsedSidebar = collapsedSidebar,
       _chatFontSizeDelta = chatFontSizeDelta,
       _messageShowIdentityNumber = messageShowIdentityNumber;

  factory SettingState.fromMap(Map<String, dynamic> map) => SettingState(
    brightnessValue: map['brightness'] as int?,
    messageShowAvatar: map['messageShowAvatar'] as bool?,
    messagePreview: map['messagePreview'] as bool?,
    photoAutoDownload: map['photoAutoDownload'] as bool?,
    videoAutoDownload: map['videoAutoDownload'] as bool?,
    fileAutoDownload: map['fileAutoDownload'] as bool?,
    collapsedSidebar: map['collapsedSidebar'] as bool?,
    chatFontSizeDelta: map['chatFontSizeDelta'] as double?,
    messageShowIdentityNumber: map['messageShowIdentityNumber'] as bool?,
  );

  final int? _brightnessValue;
  final bool? _messageShowAvatar;
  final bool? _messagePreview;
  final bool? _photoAutoDownload;
  final bool? _videoAutoDownload;
  final bool? _fileAutoDownload;
  final bool? _collapsedSidebar;
  final double? _chatFontSizeDelta;
  final bool? _messageShowIdentityNumber;

  Brightness? get brightness {
    switch (_brightnessValue) {
      case 0:
      case null:
        return null;
      case 1:
        return Brightness.dark;
      case 2:
        return Brightness.light;
      default:
        w('invalid value for brightness. $_brightnessValue');
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

  int? get brightnessValue => _brightnessValue;

  bool get messageShowAvatar => _messageShowAvatar ?? true;

  bool get messagePreview => _messagePreview ?? true;

  bool get photoAutoDownload => _photoAutoDownload ?? true;

  bool get videoAutoDownload => _videoAutoDownload ?? true;

  bool get fileAutoDownload => _fileAutoDownload ?? true;

  bool get collapsedSidebar => _collapsedSidebar ?? false;

  double get chatFontSizeDelta => _chatFontSizeDelta ?? 0;

  bool get messageShowIdentityNumber => _messageShowIdentityNumber ?? false;

  Map<String, dynamic> toMap() => {
    'brightness': brightnessValue,
    'messageShowAvatar': _messageShowAvatar,
    'messagePreview': _messagePreview,
    'photoAutoDownload': _photoAutoDownload,
    'videoAutoDownload': _videoAutoDownload,
    'fileAutoDownload': _fileAutoDownload,
    'collapsedSidebar': _collapsedSidebar,
    'chatFontSizeDelta': _chatFontSizeDelta,
    'messageShowIdentityNumber': _messageShowIdentityNumber,
  };

  SettingState copyWith({
    int? brightnessValue,
    bool? messageShowAvatar,
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
    bool? collapsedSidebar,
    double? chatFontSizeDelta,
    bool? messageShowIdentityNumber,
  }) => SettingState(
    brightnessValue: brightnessValue ?? _brightnessValue,
    messageShowAvatar: messageShowAvatar ?? _messageShowAvatar,
    messagePreview: messagePreview ?? _messagePreview,
    photoAutoDownload: photoAutoDownload ?? _photoAutoDownload,
    videoAutoDownload: videoAutoDownload ?? _videoAutoDownload,
    fileAutoDownload: fileAutoDownload ?? _fileAutoDownload,
    collapsedSidebar: collapsedSidebar ?? _collapsedSidebar,
    chatFontSizeDelta: chatFontSizeDelta ?? _chatFontSizeDelta,
    messageShowIdentityNumber:
        messageShowIdentityNumber ?? _messageShowIdentityNumber,
  );

  @override
  List<Object?> get props => [
    brightnessValue,
    _messageShowAvatar,
    _messagePreview,
    _photoAutoDownload,
    _videoAutoDownload,
    _fileAutoDownload,
    _collapsedSidebar,
    _chatFontSizeDelta,
    _messageShowIdentityNumber,
  ];
}

class SettingChangeNotifier extends Notifier<SettingState> {
  @override
  SettingState build() {
    ref.keepAlive();
    final oldJson = HydrationStorageRegistry.storage.read(_kSettingStorageKey);
    if (oldJson == null) {
      return const SettingState();
    }

    return fromHydratedJson(oldJson, SettingState.fromMap) ??
        const SettingState();
  }

  set brightness(Brightness? value) {
    final brightnessValue = switch (value) {
      Brightness.dark => 1,
      Brightness.light => 2,
      null => 0,
    };
    _update(state.copyWith(brightnessValue: brightnessValue));
  }

  Brightness? get brightness => state.brightness;

  ThemeMode get themeMode => state.themeMode;

  set messageShowAvatar(bool value) {
    if (state.messageShowAvatar == value) return;
    _update(state.copyWith(messageShowAvatar: value));
  }

  bool get messageShowAvatar => state.messageShowAvatar;

  set messageShowIdentityNumber(bool value) {
    if (state.messageShowIdentityNumber == value) return;
    _update(state.copyWith(messageShowIdentityNumber: value));
  }

  bool get messageShowIdentityNumber => state.messageShowIdentityNumber;

  set messagePreview(bool value) {
    if (state.messagePreview == value) return;
    _update(state.copyWith(messagePreview: value));
  }

  bool get messagePreview => state.messagePreview;

  set photoAutoDownload(bool value) {
    if (state.photoAutoDownload == value) return;
    _update(state.copyWith(photoAutoDownload: value));
  }

  bool get photoAutoDownload => state.photoAutoDownload;

  set videoAutoDownload(bool value) {
    if (state.videoAutoDownload == value) return;
    _update(state.copyWith(videoAutoDownload: value));
  }

  bool get videoAutoDownload => state.videoAutoDownload;

  set fileAutoDownload(bool value) {
    if (state.fileAutoDownload == value) return;
    _update(state.copyWith(fileAutoDownload: value));
  }

  bool get fileAutoDownload => state.fileAutoDownload;

  set collapsedSidebar(bool value) {
    if (state.collapsedSidebar == value) return;
    _update(state.copyWith(collapsedSidebar: value));
  }

  bool get collapsedSidebar => state.collapsedSidebar;

  set chatFontSizeDelta(double value) {
    if (state.chatFontSizeDelta == value) return;
    _update(state.copyWith(chatFontSizeDelta: value));
  }

  double get chatFontSizeDelta => state.chatFontSizeDelta;

  void _update(SettingState next) {
    HydrationStorageRegistry.storage.write(_kSettingStorageKey, next.toMap());
    state = next;
  }
}

final settingProvider =
    NotifierProvider.autoDispose<SettingChangeNotifier, SettingState>(
      SettingChangeNotifier.new,
    );
