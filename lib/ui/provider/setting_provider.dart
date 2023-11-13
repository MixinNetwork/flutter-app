import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../enum/property_group.dart';
import '../../utils/db/db_key_value.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hydrated_bloc.dart';
import '../../utils/proxy.dart';
import 'database_provider.dart';

final settingProvider = ChangeNotifierProvider<AppSettingKeyValue>(
    (ref) => ref.watch(appDatabaseProvider).settingKeyValue);

class AppSettingKeyValue extends AppKeyValue {
  AppSettingKeyValue(KeyValueDao<AppPropertyGroup> dao)
      : super(group: AppPropertyGroup.setting, dao: dao) {
    _migration();
  }
}

const _kEnableProxyKey = 'enable_proxy';
const _kSelectedProxyKey = 'selected_proxy';
const _kProxyListKey = 'proxy_list';

extension ProxySetting on AppSettingKeyValue {
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

const _keyChatFontSizeDelta = 'chatFontSizeDelta';
const _keyMessageShowIdentityNumber = 'messageShowIdentityNumber';
const _keyMessageShowAvatar = 'messageShowAvatar';

extension ChatSetting on AppSettingKeyValue {
  double get chatFontSizeDelta => get(_keyChatFontSizeDelta) ?? 0.0;

  set chatFontSizeDelta(double value) => set(_keyChatFontSizeDelta, value);

  bool get messageShowIdentityNumber =>
      get(_keyMessageShowIdentityNumber) ?? false;

  set messageShowIdentityNumber(bool value) =>
      set(_keyMessageShowIdentityNumber, value);

  bool get messageShowAvatar => get(_keyMessageShowAvatar) ?? true;

  set messageShowAvatar(bool value) => set(_keyMessageShowAvatar, value);
}

const _keyBrightness = 'brightness';
const _keyCollapsedSidebar = 'collapsedSidebar';

extension ApperenceSetting on AppSettingKeyValue {
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

  int? get _brightness => get(_keyBrightness);

  set _brightness(int? value) => set(_keyBrightness, value);

  bool get collapsedSidebar => get(_keyCollapsedSidebar) ?? false;

  set collapsedSidebar(bool value) => set(_keyCollapsedSidebar, value);
}

const _keyMessagePreview = 'messagePreview';

extension NotificationSetting on AppSettingKeyValue {
  bool get messagePreview => get(_keyMessagePreview) ?? true;

  set messagePreview(bool value) => set(_keyMessagePreview, value);
}

const _keyPhotoAutoDownload = 'photoAutoDownload';
const _keyVideoAutoDownload = 'videoAutoDownload';
const _keyFileAutoDownload = 'fileAutoDownload';

extension AutoDownloadSetting on AppSettingKeyValue {
  bool get photoAutoDownload => get(_keyPhotoAutoDownload) ?? true;

  set photoAutoDownload(bool value) => set(_keyPhotoAutoDownload, value);

  bool get videoAutoDownload => get(_keyVideoAutoDownload) ?? true;

  set videoAutoDownload(bool value) => set(_keyVideoAutoDownload, value);

  bool get fileAutoDownload => get(_keyFileAutoDownload) ?? true;

  set fileAutoDownload(bool value) => set(_keyFileAutoDownload, value);
}

const _keySettingHasMigratedFromHive = 'settingHasMigratedFromHive';

extension SettingMigration on AppSettingKeyValue {
  bool get settingHasMigratedFromHive =>
      get(_keySettingHasMigratedFromHive) ?? false;

  set settingHasMigratedFromHive(bool value) =>
      set(_keySettingHasMigratedFromHive, value);

  Future<void> _migration() async {
    await initialized;
    if (settingHasMigratedFromHive) {
      return;
    }
    settingHasMigratedFromHive = true;
    final oldJson = HydratedBloc.storage.read(_kSettingCubitKey);
    if (oldJson == null) {
      return;
    }
    // we have not necessary to delete the old key
    // unawaited(HydratedBloc.storage.delete(_kSettingCubitKey));
    final settingState = fromHydratedJson(oldJson, _SettingState.fromMap);
    if (settingState == null) {
      return;
    }
    if (settingState._brightness != null) {
      _brightness = settingState._brightness;
    }
    if (settingState._messageShowAvatar != null) {
      messageShowAvatar = settingState._messageShowAvatar!;
    }
    if (settingState._messagePreview != null) {
      messagePreview = settingState._messagePreview!;
    }
    if (settingState._photoAutoDownload != null) {
      photoAutoDownload = settingState._photoAutoDownload!;
    }
    if (settingState._videoAutoDownload != null) {
      videoAutoDownload = settingState._videoAutoDownload!;
    }
    if (settingState._fileAutoDownload != null) {
      fileAutoDownload = settingState._fileAutoDownload!;
    }
    if (settingState._collapsedSidebar != null) {
      collapsedSidebar = settingState._collapsedSidebar!;
    }
    if (settingState._chatFontSizeDelta != null) {
      chatFontSizeDelta = settingState._chatFontSizeDelta!;
    }
    if (settingState._messageShowIdentityNumber != null) {
      messageShowIdentityNumber = settingState._messageShowIdentityNumber!;
    }
  }
}

// setting cubit key in legacy hive
const _kSettingCubitKey = 'SettingCubit';

// setting cubit object in legacy hive
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
    bool? messageShowIdentityNumber,
  })  : _brightness = brightness,
        _messageShowAvatar = messageShowAvatar,
        _messagePreview = messagePreview,
        _photoAutoDownload = photoAutoDownload,
        _videoAutoDownload = videoAutoDownload,
        _fileAutoDownload = fileAutoDownload,
        _collapsedSidebar = collapsedSidebar,
        _chatFontSizeDelta = chatFontSizeDelta,
        _messageShowIdentityNumber = messageShowIdentityNumber;

  factory _SettingState.fromMap(Map<String, dynamic> map) => _SettingState(
        brightness: map['brightness'] as int?,
        messageShowAvatar: map['messageShowAvatar'] as bool?,
        messagePreview: map['messagePreview'] as bool?,
        photoAutoDownload: map['photoAutoDownload'] as bool?,
        videoAutoDownload: map['videoAutoDownload'] as bool?,
        fileAutoDownload: map['fileAutoDownload'] as bool?,
        collapsedSidebar: map['collapsedSidebar'] as bool?,
        chatFontSizeDelta: map['chatFontSizeDelta'] as double?,
        messageShowIdentityNumber: map['messageShowIdentityNumber'] as bool?,
      );

  final int? _brightness;
  final bool? _messageShowAvatar;
  final bool? _messagePreview;
  final bool? _photoAutoDownload;
  final bool? _videoAutoDownload;
  final bool? _fileAutoDownload;
  final bool? _collapsedSidebar;
  final double? _chatFontSizeDelta;
  final bool? _messageShowIdentityNumber;

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
        _messageShowIdentityNumber,
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
        'messageShowIdentityNumber': _messageShowIdentityNumber,
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
    bool? messageShowIdentityNumber,
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
        messageShowIdentityNumber:
            messageShowIdentityNumber ?? _messageShowIdentityNumber,
      );
}
