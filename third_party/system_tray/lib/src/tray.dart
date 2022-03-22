import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' show dirname, joinAll;

import 'menu_item.dart';

const String _kChannelName = "flutter/system_tray";

const String _kInitSystemTray = "InitSystemTray";
const String _kSetSystemTrayInfo = "SetSystemTrayInfo";
const String _kSetContextMenu = "SetContextMenu";
const String _kPopupContextMenu = "PopupContextMenu";
const String _kGetTitle = "GetTitle";

const String _kMenuItemSelectedCallbackMethod = 'MenuItemSelectedCallback';
const String _kSystemTrayEventCallbackMethod = 'SystemTrayEventCallback';

const String _kTitleKey = "title";
const String _kIconPathKey = "iconpath";
const String _kToolTipKey = "tooltip";
const String _kIdKey = 'id';
const String _kTypeKey = 'type';
const String _kLabelKey = 'label';
const String _kSubMenuKey = 'submenu';
const String _kEnabledKey = 'enabled';

/// A callback provided to [SystemTray] to handle system tray click event.
typedef SystemTrayEventCallback = void Function(String eventName);

/// Representation of system tray
class SystemTray {
  SystemTray() {
    _platformChannel.setMethodCallHandler(_callbackHandler);
  }

  static const MethodChannel _platformChannel = MethodChannel(_kChannelName);

  /// Map from unique identifiers assigned by this class to the callbacks for
  /// those menu items.
  final Map<int, MenuItemSelectedCallback> _selectionCallbacks = {};

  /// The ID to use the next time a menu item needs an ID assigned.
  int _nextMenuItemId = 1;

  /// Whether or not a call to [_kMenuSetMethod] is outstanding.
  ///
  /// This is used to drop any menu callbacks that aren't received until
  /// after a new call to setMenu, so that clients don't received unexpected
  /// stale callbacks.
  bool _updateInProgress = false;

  //
  SystemTrayEventCallback? _systemTrayEventCallback;

  /// Show a SystemTray icon
  Future<bool> initSystemTray({
    required String title,
    required String iconPath,
    String? toolTip,
  }) async {
    bool value = await _platformChannel.invokeMethod(
      _kInitSystemTray,
      <String, dynamic>{
        _kTitleKey: title,
        _kIconPathKey: await _getIcon(iconPath),
        _kToolTipKey: toolTip,
      },
    );
    return value;
  }

  /// Set system info info
  Future<bool> setSystemTrayInfo({
    String? title,
    String? iconPath,
    String? toolTip,
  }) async {
    bool value = await _platformChannel.invokeMethod(
      _kSetSystemTrayInfo,
      <String, dynamic>{
        _kTitleKey: title,
        _kIconPathKey: iconPath == null ? null : await _getIcon(iconPath),
        _kToolTipKey: toolTip,
      },
    );
    return value;
  }

  /// (Windows\macOS\Linux) Sets the image associated with this tray icon
  Future<void> setImage(String image) async {
    await setSystemTrayInfo(iconPath: image);
  }

  /// (Windows\macOS) Sets the hover text for this tray icon.
  Future<void> setToolTip(String toolTip) async {
    await setSystemTrayInfo(toolTip: toolTip);
  }

  /// (macOS) Sets the title displayed next to the tray icon in the status bar.
  Future<void> setTitle(String title) async {
    await setSystemTrayInfo(title: title);
  }

  /// (macOS) Returns string - the title displayed next to the tray icon in the status bar
  Future<String> getTitle() async {
    return await _platformChannel.invokeMethod(_kGetTitle);
  }

  /// register listener for system tray event.
  void registerSystemTrayEventHandler(SystemTrayEventCallback callback) {
    _systemTrayEventCallback = callback;
  }

  /// Sets the native application menu to [menus].
  ///
  /// How exactly this is handled is subject to platform interpretation.
  /// For instance, special menus that are handled entirely on the native
  /// side might be added to the provided menus.
  Future<void> setContextMenu(List<MenuItemBase> menus) async {
    try {
      _updateInProgress = true;
      await _platformChannel.invokeMethod(
          _kSetContextMenu, _channelRepresentationForMenus(menus));
      _updateInProgress = false;
    } on PlatformException catch (e) {
      debugPrint('Platform exception setting menu: ${e.message}');
    }
  }

  /// Pop up the context menu.
  ///
  Future<void> popUpContextMenu() async {
    await _platformChannel.invokeMethod(_kPopupContextMenu);
  }

  /// Converts [menus] to a representation that can be sent in the arguments to
  /// [_kMenuSetMethod].
  ///
  /// As a side-effect, repopulates _selectionCallbacks with a mapping from
  /// the IDs assigned to any menu item with a selection handler to the
  /// callback that should be triggered.
  List<dynamic> _channelRepresentationForMenus(List<MenuItemBase> menus) {
    _selectionCallbacks.clear();
    _nextMenuItemId = 1;

    return menus.map(_channelRepresentationForMenuItem).toList();
  }

  /// Returns a representation of [item] suitable for passing over the
  /// platform channel to the native plugin.
  Map<String, dynamic> _channelRepresentationForMenuItem(MenuItemBase item) {
    final representation = <String, dynamic>{};
    if (item is MenuSeparator) {
      representation[_kTypeKey] = item.type;
    } else {
      representation[_kLabelKey] = item.label;
      if (item is SubMenu) {
        representation[_kTypeKey] = item.type;
        representation[_kSubMenuKey] =
            _channelRepresentationForMenu(item.children);
      } else if (item is MenuItem) {
        representation[_kTypeKey] = item.type;
        final handler = item.onClicked;
        if (handler != null) {
          representation[_kIdKey] = _storeMenuCallback(handler);
        }
        representation[_kEnabledKey] = item.enabled;
      } else {
        throw ArgumentError(
            'Unknown MenuItemBase type: $item (${item.runtimeType})');
      }
    }
    return representation;
  }

  /// Returns the representation of [menu] suitable for passing over the
  /// platform channel to the native plugin.
  List<dynamic> _channelRepresentationForMenu(List<MenuItemBase> menu) {
    final menuItemRepresentations = [];
    // Dividers are only allowed after non-divider items (see ApplicationMenu).
    var skipNextDivider = true;
    for (final menuItem in menu) {
      final isDivider = menuItem is MenuSeparator;
      if (isDivider && skipNextDivider) {
        continue;
      }
      skipNextDivider = isDivider;
      menuItemRepresentations.add(_channelRepresentationForMenuItem(menuItem));
    }
    // If the last item is a divider, remove it (see ApplicationMenu).
    if (skipNextDivider && menuItemRepresentations.isNotEmpty) {
      menuItemRepresentations.removeLast();
    }
    return menuItemRepresentations;
  }

  /// Stores [callback] for use plugin callback handling, returning the ID
  /// under which it was stored.
  ///
  /// The returned ID should be attached to the menu so that the native plugin
  /// can identify the menu item selected in the callback.
  int _storeMenuCallback(MenuItemSelectedCallback callback) {
    final id = _nextMenuItemId++;
    _selectionCallbacks[id] = callback;
    return id;
  }

  Future<void> _callbackHandler(MethodCall methodCall) async {
    if (methodCall.method == _kMenuItemSelectedCallbackMethod) {
      if (_updateInProgress) {
        // Drop stale callbacks.
        // TODO: Evaluate whether this works in practice, or if races are
        // regular occurences that clients will need to be prepared to
        // handle (in which case a more complex ID system will be needed).
        debugPrint(
            'Warning: Menu selection callback received during menu update.');
        return;
      }
      final int menuItemId = methodCall.arguments;
      final callback = _selectionCallbacks[menuItemId];
      if (callback == null) {
        throw Exception('Unknown menu item ID $menuItemId');
      }
      callback();
    } else if (methodCall.method == _kSystemTrayEventCallbackMethod) {
      if (_systemTrayEventCallback != null) {
        final String eventName = methodCall.arguments;
        _systemTrayEventCallback!(eventName);
      }
    }
  }

  /// Get Icon
  Future<String> _getIcon(String assetPath) async {
    if (assetPath.isEmpty == true) {
      return '';
    }

    if (Platform.isMacOS) {
      return await _base64Image(assetPath);
    }

    return joinAll([
      dirname(Platform.resolvedExecutable),
      'data/flutter_assets',
      assetPath,
    ]);
  }

  /// Returns Base64 Image
  Future<String> _base64Image(String iconPath) async {
    ByteData imageData = await rootBundle.load(iconPath);
    return base64Encode(imageData.buffer.asUint8List());
  }
}
