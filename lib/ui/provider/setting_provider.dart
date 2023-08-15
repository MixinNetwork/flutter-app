// ignore_for_file: deprecated_consistency
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../db/global_hive.dart';
import '../../utils/hydrated_bloc.dart';
import '../../utils/logger.dart';

@Deprecated('Use settingProvider instead')
class _SettingState extends Equatable {
  const _SettingState({
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

  factory _SettingState.fromMap(Map<String, dynamic> map) => _SettingState(
        brightness: map['brightness'] as int?,
        messageShowAvatar: map['messageShowAvatar'] as bool?,
        messagePreview: map['messagePreview'] as bool?,
        photoAutoDownload: map['photoAutoDownload'] as bool?,
        videoAutoDownload: map['videoAutoDownload'] as bool?,
        fileAutoDownload: map['fileAutoDownload'] as bool?,
        collapsedSidebar: map['collapsedSidebar'] as bool?,
        chatFontSizeDelta: map['chatFontSizeDelta'] as double?,
      );

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

  _SettingState copyWith({
    int? brightness,
    bool? messageShowAvatar,
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
    bool? collapsedSidebar,
    double? chatFontSizeDelta,
  }) =>
      _SettingState(
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

class SettingChangeNotifier extends ChangeNotifier {
  SettingChangeNotifier({
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

  static const _kSettingBrightnessKey = 'settings_brightness';
  static const _kSettingMessageShowAvatarKey = 'settings_messageShowAvatar';
  static const _kSettingMessagePreviewKey = 'settings_messagePreview';
  static const _kSettingPhotoAutoDownloadKey = 'settings_photoAutoDownload';
  static const _kSettingVideoAutoDownloadKey = 'settings_videoAutoDownload';
  static const _kSettingFileAutoDownloadKey = 'settings_fileAutoDownload';
  static const _kSettingCollapsedSidebarKey = 'settings_collapsedSidebar';
  static const _kSettingChatFontSizeDeltaKey = 'settings_chatFontSizeDelta';

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
  int? _brightness;
  bool? _messageShowAvatar;
  bool? _messagePreview;
  bool? _photoAutoDownload;
  bool? _videoAutoDownload;
  bool? _fileAutoDownload;
  bool? _collapsedSidebar;
  double? _chatFontSizeDelta;

  /// [brightness] null to follow system.
  set brightness(Brightness? value) {
    switch (value) {
      case Brightness.dark:
        _brightness = 1;
        break;
      case Brightness.light:
        _brightness = 2;
        break;
      case null:
        _brightness = 0;
        break;
    }
    globalBox.put(_kSettingBrightnessKey, _brightness);
    notifyListeners();
  }

  Brightness? get brightness {
    switch (_brightness) {
      case 0:
      case null:
        return null;
      case 1:
        return Brightness.dark;
      case 2:
        return Brightness.light;
      default:
        w('invalid value for brightness. $_brightness');
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

  set messageShowAvatar(bool value) {
    if (_messageShowAvatar == value) return;

    _messageShowAvatar = value;
    globalBox.put(_kSettingMessageShowAvatarKey, _messageShowAvatar);
    notifyListeners();
  }

  bool get messageShowAvatar => _messageShowAvatar ?? false;

  set messagePreview(bool value) {
    if (_messagePreview == value) return;

    _messagePreview = value;
    globalBox.put(_kSettingMessagePreviewKey, _messagePreview);
    notifyListeners();
  }

  bool get messagePreview => _messagePreview ?? true;

  set photoAutoDownload(bool value) {
    if (_photoAutoDownload == value) return;

    _photoAutoDownload = value;
    globalBox.put(_kSettingPhotoAutoDownloadKey, _photoAutoDownload);
    notifyListeners();
  }

  bool get photoAutoDownload => _photoAutoDownload ?? true;

  set videoAutoDownload(bool value) {
    if (_videoAutoDownload == value) return;

    _videoAutoDownload = value;
    globalBox.put(_kSettingVideoAutoDownloadKey, _videoAutoDownload);
    notifyListeners();
  }

  bool get videoAutoDownload => _videoAutoDownload ?? true;

  set fileAutoDownload(bool value) {
    if (_fileAutoDownload == value) return;

    _fileAutoDownload = value;
    globalBox.put(_kSettingFileAutoDownloadKey, _fileAutoDownload);
    notifyListeners();
  }

  bool get fileAutoDownload => _fileAutoDownload ?? true;

  set collapsedSidebar(bool value) {
    if (_collapsedSidebar == value) return;

    _collapsedSidebar = value;
    globalBox.put(_kSettingCollapsedSidebarKey, _collapsedSidebar);
    notifyListeners();
  }

  bool get collapsedSidebar => _collapsedSidebar ?? false;

  set chatFontSizeDelta(double value) {
    if (_chatFontSizeDelta == value) return;

    _chatFontSizeDelta = value;
    globalBox.put(_kSettingChatFontSizeDeltaKey, _chatFontSizeDelta);
    notifyListeners();
  }

  double get chatFontSizeDelta => _chatFontSizeDelta ?? 0;
}

@Deprecated('Use SettingChangeNotifier instead')
const _kSettingCubitKey = 'SettingCubit';

final settingProvider =
    ChangeNotifierProvider.autoDispose<SettingChangeNotifier>((ref) {
  ref.keepAlive();

  //migrate
  {
    final oldJson = HydratedBloc.storage.read(_kSettingCubitKey);
    if (oldJson != null) {
      final settingState = fromHydratedJson(oldJson, _SettingState.fromMap);
      if (settingState == null) return SettingChangeNotifier();

      HydratedBloc.storage.delete(_kSettingCubitKey);

      return SettingChangeNotifier(
        brightness: settingState.brightness,
        messageShowAvatar: settingState.messageShowAvatar,
        messagePreview: settingState.messagePreview,
        photoAutoDownload: settingState.photoAutoDownload,
        videoAutoDownload: settingState.videoAutoDownload,
        fileAutoDownload: settingState.fileAutoDownload,
        collapsedSidebar: settingState.collapsedSidebar,
        chatFontSizeDelta: settingState.chatFontSizeDelta,
      );
    }
  }

  final brightness =
      globalBox.get(SettingChangeNotifier._kSettingBrightnessKey);
  final messageShowAvatar =
      globalBox.get(SettingChangeNotifier._kSettingMessageShowAvatarKey);
  final messagePreview =
      globalBox.get(SettingChangeNotifier._kSettingMessagePreviewKey);
  final photoAutoDownload =
      globalBox.get(SettingChangeNotifier._kSettingPhotoAutoDownloadKey);
  final videoAutoDownload =
      globalBox.get(SettingChangeNotifier._kSettingVideoAutoDownloadKey);
  final fileAutoDownload =
      globalBox.get(SettingChangeNotifier._kSettingFileAutoDownloadKey);
  final collapsedSidebar =
      globalBox.get(SettingChangeNotifier._kSettingCollapsedSidebarKey);
  final chatFontSizeDelta =
      globalBox.get(SettingChangeNotifier._kSettingChatFontSizeDeltaKey);
  return SettingChangeNotifier(
    brightness: brightness is int ? brightness : null,
    messageShowAvatar: messageShowAvatar is bool ? messageShowAvatar : null,
    messagePreview: messagePreview is bool ? messagePreview : null,
    photoAutoDownload: photoAutoDownload is bool ? photoAutoDownload : null,
    videoAutoDownload: videoAutoDownload is bool ? videoAutoDownload : null,
    fileAutoDownload: fileAutoDownload is bool ? fileAutoDownload : null,
    collapsedSidebar: collapsedSidebar is bool ? collapsedSidebar : null,
    chatFontSizeDelta: chatFontSizeDelta is double ? chatFontSizeDelta : null,
  );
});
