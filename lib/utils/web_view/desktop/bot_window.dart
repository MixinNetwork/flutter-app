import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app.dart' show rootRouteObserver;
import '../../../constants/brightness_theme_data.dart';
import '../../../constants/constants.dart';
import '../../../db/extension/app.dart';
import '../../../db/mixin_database.dart';
import '../../../ui/provider/setting_provider.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/global_image_cache.dart';
import '../../../widgets/message/item/action_card/action_card_data.dart';
import '../../extension/extension.dart';
import '../../logger.dart';
import '../../uri_utils.dart';

/// Talks to the runner's native composer (BotWindowComposer on each platform).
const _channel = MethodChannel('one.mixin/bot_window');

/// A browser window opened by the app: a bot or a plain web page, with the
/// mobile-style capsule drawn by the runner's composer.
class BotWindow {
  BotWindow._({
    required this.webview,
    required this.key,
    required this.app,
    required this.appCardData,
    required this.conversationId,
    required String themeKey,
  }) : _themeKey = themeKey;

  static final _windows = <int, BotWindow>{};

  /// The last theme-color of each bot or site, so a reopened window starts
  /// with it instead of the default.
  static final _themeColors = <String, Color>{};

  /// Bot icons as decoded PNGs, so a reopened window shows the icon at once.
  static final _icons = <String, Uint8List>{};
  static _AppearanceObserver? _appearance;
  static var _hasComposer = true;

  /// Popups that have a Flutter view, by view id. Rendered by
  /// `BotWindowPopupHost` in the main window's engine.
  static final popups = ValueNotifier<Map<int, BotWindow>>(const {});

  final Webview webview;
  final String key;
  final App? app;
  final AppCardData? appCardData;
  final String? conversationId;

  int? _popupViewId;

  /// The capsule's frame in the popup view, for the menu to hang from.
  Rect popupAnchor = Rect.zero;

  /// Whether the popup's Flutter view shows the menu.
  final popupVisible = ValueNotifier(false);
  Completer<void>? _popupHidden;

  final String _themeKey;
  Color? _themeColor;
  String? _lastHandledUrl;
  var _lastHandledAt = DateTime.fromMillisecondsSinceEpoch(0);
  var _wasLoading = false;
  late Brightness _brightness;

  bool get isBot => app != null;

  /// The newest window for [key]: one the runner could not focus is left
  /// alone when the key opens again.
  static BotWindow? find(String key) =>
      _windows.values.where((window) => window.key == key).lastOrNull;

  static void closeAll() {
    for (final window in [..._windows.values]) {
      unawaited(window.webview.close());
    }
  }

  static Future<BotWindow> open(
    BuildContext context, {
    required String key,
    required String url,
    required String title,
    required App? app,
    required AppCardData? appCardData,
    required String? conversationId,
    required String version,
    required WindowsWebviewOptions windows,
  }) async {
    _channel.setMethodCallHandler(_handleNativeCall);
    _appearance ??= _AppearanceObserver(context.settingChangeNotifier);
    final brightness = context.brightness;
    final immersive = app?.capabilitiesList?.contains('IMMERSIVE') ?? false;
    final themeKey = app?.appId ?? Uri.tryParse(url)?.origin ?? url;
    final background =
        _themeColors[themeKey] ?? _defaultChromeColor(brightness);
    final l10n = context.l10n;
    // Every runner decodes the standard codec; not all of them have JSON.
    final arguments = const StandardMessageCodec().encodeMessage({
      'immersive': immersive,
      'title': title,
      'followPageTitle': app == null,
      'showIcon': app != null,
      'icon': ?_icons[app?.appId],
      'backgroundColor': background.toARGB32(),
      'dark': background.computeLuminance() < 0.5,
      // Native fallback menu where a Flutter view is unavailable (X11).
      'menu': {
        'refresh': l10n.refresh,
        'copyLink': l10n.copyLink,
        'openInBrowser': l10n.openInBrowser,
        'close': l10n.close,
      },
    })!;
    final webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        windowWidth: 380,
        windowHeight: 750,
        title: title,
        brightness: brightness,
        windows: windows,
        // The encoded bytes are a view of a larger buffer.
        composerArguments: base64Encode(
          arguments.buffer.asUint8List(
            arguments.offsetInBytes,
            arguments.lengthInBytes,
          ),
        ),
      ),
    );
    final window = BotWindow._(
      webview: webview,
      key: key,
      app: app,
      appCardData: appCardData,
      conversationId: conversationId,
      themeKey: themeKey,
    ).._brightness = brightness;
    _windows[webview.id] = window;
    // `appearance` is read from prefers-color-scheme when the page asks,
    // which follows setBrightness, so no script is added per change.
    await window._setUp(version, {
      'app_version': version,
      'immersive': immersive,
      'platform': 'Desktop',
      'locale': Localizations.localeOf(context).toLanguageTag(),
      'conversation_id': conversationId ?? '',
      'currency': context.account?.fiatCurrency,
    });
    await webview.launch(url);
    if (app != null && !immersive) {
      unawaited(window._loadIcon(context, app));
    }
    return window;
  }

  Future<void> _setUp(String version, Map<String, Object?> context) async {
    webview.navigationState.addListener(_onNavigationStateChanged);
    unawaited(
      webview.onClose.then((_) {
        webview.navigationState.removeListener(_onNavigationStateChanged);
        _windows.remove(webview.id);
        final viewId = _popupViewId;
        if (viewId != null) {
          popups.value = {...popups.value}..remove(viewId);
        }
      }),
    );

    webview
      ..addJavaScriptHandler('reloadTheme', (_, _) => _reloadTheme())
      ..addJavaScriptHandler('close', (_, _) => webview.close())
      ..addJavaScriptHandler('openInBrowser', (data, _) {
        // Any page in the window can call it: web links only.
        final uri = data is String ? Uri.tryParse(data) : null;
        if (uri != null && _isWeb(uri)) unawaited(launchUrl(uri));
      });
    await webview.addScriptToExecuteOnDocumentCreated(
      _mixinContextScript(jsonEncode(context)),
    );
    await webview.setApplicationNameForUserAgent(' Mixin/$version');
    await webview.setOnUrlRequestCallback(_onUrlRequest);
  }

  Future<void> _updateAppearance(Brightness brightness) async {
    if (brightness == _brightness) return;
    _brightness = brightness;
    try {
      // WebKitGTK follows GTK's dark theme preference, which the app sets
      // for every window; the plugin throws there.
      if (defaultTargetPlatform != TargetPlatform.linux) {
        await webview.setBrightness(brightness);
      }
    } catch (error) {
      w('set bot window brightness failed: $error');
    }
    try {
      // The page re-reads a theme-color that depends on the appearance once
      // it sees the change.
      if (_themeColor == null) await _applyChrome(null);
    } catch (error) {
      w('update bot window chrome failed: $error');
    }
  }

  void _onNavigationStateChanged() {
    final loading = webview.navigationState.value.isLoading;
    if (_wasLoading && !loading) unawaited(_reloadTheme());
    _wasLoading = loading;
  }

  Future<void> _reloadTheme() async {
    try {
      final color = await webview.evaluateJavaScript(_themeColorScript);
      final parsed = _themeColor = color is String
          ? _parseCssColor(color)
          : null;
      if (parsed != null) {
        _themeColors[_themeKey] = parsed;
      } else {
        _themeColors.remove(_themeKey);
      }
      await _applyChrome(parsed);
    } catch (error) {
      w('read theme-color failed: $error');
    }
  }

  Future<void> _applyChrome(Color? themeColor) async {
    final color = themeColor ?? _defaultChromeColor(_brightness);
    await _invoke('setChrome', {
      'backgroundColor': color.toARGB32(),
      'dark': color.computeLuminance() < 0.5,
    });
  }

  /// Decodes the icon here, as for avatars in chats, and hands the runner a
  /// small PNG: the cached copy first, then a fresher one if it changed.
  Future<void> _loadIcon(BuildContext context, App app) async {
    try {
      final proxy = context.database.settingProperties.activatedProxy;
      await for (final bytes in GlobalImageCache.instance.getBytes(
        app.iconUrl,
        limitBytes: true,
        proxyConfig: proxy,
      )) {
        await showIcon(bytes);
      }
    } catch (error) {
      w('load bot icon failed: $error');
    }
  }

  @visibleForTesting
  Future<void> showIcon(Uint8List bytes) async {
    final codec = await instantiateImageCodec(
      bytes,
      targetWidth: _iconPixels,
      targetHeight: _iconPixels,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    final png = await frame.image.toByteData(format: ImageByteFormat.png);
    frame.image.dispose();
    if (png == null) return;
    final icon = png.buffer.asUint8List();
    if (app case final app?) _icons[app.appId] = icon;
    await _invoke('setChrome', {'icon': icon});
  }

  bool _onUrlRequest(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    if (_isWalletConnect(uri)) return false;
    if (_isWeb(uri) && !uri.isMixinActionUrl) return true;
    if (scheme == 'file' ||
        scheme == 'about' ||
        scheme == 'data' ||
        scheme == 'blob') {
      return true;
    }

    // mixin: links and Mixin action links go through the same handling as
    // links in a chat; other schemes open another app once confirmed.
    final now = DateTime.now();
    if (url == _lastHandledUrl &&
        now.difference(_lastHandledAt) < const Duration(seconds: 1)) {
      return false;
    }
    _lastHandledUrl = url;
    _lastHandledAt = now;
    unawaited(_openInApp(uri));
    return false;
  }

  Future<void> _openInApp(Uri uri) async {
    // Dialogs belong to the main window.
    final context = await showMainWindow();
    if (context == null || !context.mounted) return;
    if (uri.isScheme(mixinScheme) || uri.isMixinActionUrl) {
      await openUri(context, uri.toString(), app: app, confirmSend: true);
      return;
    }
    // The page may navigate without a click, so another app is never
    // started unasked.
    final event = await showConfirmMixinDialog(
      context,
      context.l10n.openLink(uri.toString()),
    );
    if (event == DialogEvent.positive) await launchUrl(uri);
  }

  /// Hides the popup and brings the main window to front, for dialogs that
  /// act on the account. Returns the main window's navigator context.
  Future<BuildContext?> showMainWindow() async {
    await hidePopup();
    await windowManager.show();
    await windowManager.focus();
    return rootRouteObserver.navigator?.context;
  }

  /// Shows the menu for the `•••` button.
  Future<void> showPopup() async {
    try {
      final result = await _invoke<Map<Object?, Object?>>('showPopup', {
        // Windows resolves the engine from it.
        'engineId': PlatformDispatcher.instance.engineId,
      });
      if (result == null) return;
      final viewId = result['viewId']! as int;
      final [x, y, width, height] = [
        for (final value in result['anchor']! as List)
          (value! as num).toDouble(),
      ];
      popupAnchor = Rect.fromLTWH(x, y, width, height);
      _popupViewId = viewId;
      popups.value = {...popups.value, viewId: this};
      popupVisible.value = true;
    } catch (error) {
      e('show bot window popup failed: $error');
    }
  }

  Future<void> hidePopup() async {
    if (!popupVisible.value) return;
    final hidden = _popupHidden = Completer<void>();
    popupVisible.value = false;
    // Let the menu animate out and leave an empty frame, so the next show
    // does not flash the old menu. The view may be gone already.
    await hidden.future.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {},
    );
    await WidgetsBinding.instance.endOfFrame;
    // Shown again while animating out.
    if (popupVisible.value) return;
    await _invoke<void>('hidePopup');
  }

  /// Called by the popup once its exit animation has finished.
  void popupDismissed() {
    final hidden = _popupHidden;
    _popupHidden = null;
    if (hidden != null && !hidden.isCompleted) hidden.complete();
  }

  /// Returns false where the runner cannot focus the window: it has no
  /// composer, did not compose this window, or has closed it already.
  Future<bool> focus() async => await _invoke<bool>('focus') ?? false;

  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!_hasComposer) return null;
    try {
      return await _channel.invokeMethod<T>(method, {
        'browserId': webview.id,
        ...?arguments,
      });
    } on MissingPluginException {
      // A runner without BotWindowComposer, such as a test host, keeps the
      // plugin's default title bar.
      _hasComposer = false;
      return null;
    } on PlatformException catch (error) {
      // The runner did not compose this window, or has already closed it
      // while Dart still waits for onClose.
      if (error.code != 'no_window') rethrow;
      w('bot window $method: ${error.message}');
      return null;
    }
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    final arguments = call.arguments as Map?;
    final window = _windows[arguments?['browserId']];
    if (window == null) return;
    switch (call.method) {
      case 'onMoreTapped':
        await window.showPopup();
      case 'onDismissPopup':
        await window.hidePopup();
    }
  }
}

/// Re-themes every browser window when the app's appearance changes.
class _AppearanceObserver with WidgetsBindingObserver {
  _AppearanceObserver(this._settings) {
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_update);
  }

  final SettingChangeNotifier _settings;

  @override
  void didChangePlatformBrightness() => _update();

  void _update() {
    final brightness =
        _settings.brightness ?? PlatformDispatcher.instance.platformBrightness;
    for (final window in BotWindow._windows.values) {
      unawaited(window._updateAppearance(brightness));
    }
  }
}

/// The 24pt icon at up to 3x.
const _iconPixels = 72;

Color _defaultChromeColor(Brightness brightness) =>
    brightness == Brightness.dark
    ? darkBrightnessThemeData.primary
    : lightBrightnessThemeData.primary;

bool _isWeb(Uri uri) => uri.isScheme('http') || uri.isScheme('https');

bool _isWalletConnect(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'wc') return true;
  if (scheme == mixinScheme) return uri.host == 'wc';
  return (uri.host == mixinHost || uri.host == 'www.$mixinHost') &&
      uri.pathSegments.firstOrNull == 'wc';
}

/// Parses the computed CSS color returned by [_themeColorScript]:
/// `rgb(r, g, b)` or `rgba(r, g, b, a)`.
Color? _parseCssColor(String value) {
  final match = RegExp(
    r'^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  final alpha = double.tryParse(match.group(4) ?? '1') ?? 1;
  // A transparent theme-color is ignored, as on Android.
  if (alpha == 0) return null;
  return Color.fromARGB(
    255,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// The first `theme-color` matching the current media, normalized by the
/// browser to `rgb()`. Android reads the first one as written.
const _themeColorScript = '''
(function() {
  var metas = document.querySelectorAll('meta[name="theme-color"][content]');
  for (var i = 0; i < metas.length; i++) {
    var media = metas[i].getAttribute('media');
    if (media && !window.matchMedia(media).matches) continue;
    var probe = document.createElement('div');
    probe.style.color = metas[i].getAttribute('content');
    if (!probe.style.color) return '';
    document.documentElement.appendChild(probe);
    var color = getComputedStyle(probe).color;
    probe.remove();
    return color;
  }
  return '';
})();
''';

/// `window.MixinContext` in the shape of the Android bridge. Methods the
/// desktop app cannot serve answer their callbacks at once with the value
/// Android uses when it declines, so pages never wait.
String _mixinContextScript(String contextJson) =>
    '''
(function() {
  var context = $contextJson;
  function post(name, data) {
    window.desktopWebview.postMessage(name, data === undefined ? null : data);
  }
  function reply(callback, value) {
    if (typeof callback !== 'string' ||
        !/^[A-Za-z_\$][\\w\$]*(\\.[A-Za-z_\$][\\w\$]*)*\$/.test(callback)) {
      return;
    }
    setTimeout(function() {
      var target = window;
      var owner = window;
      var path = callback.split('.');
      for (var i = 0; i < path.length && target; i++) {
        owner = target;
        target = target[path[i]];
      }
      if (typeof target === 'function') target.call(owner, value);
    }, 0);
  }
  window.MixinContext = {
    getContext: function() {
      context.appearance =
          window.matchMedia('(prefers-color-scheme: dark)').matches
              ? 'dark' : 'light';
      return JSON.stringify(context);
    },
    reloadTheme: function() { post('reloadTheme'); },
    close: function() { post('close'); },
    openInBrowser: function(url) { post('openInBrowser', String(url)); return true; },
    showToast: function() {},
    playlist: function() {},
    getAssets: function(list, callback) { reply(callback, '[]'); },
    getTipAddress: function(chainId, callback) { reply(callback, ''); },
    tipSign: function(chainId, message, callback) { reply(callback, ''); },
    verifyPin: function(callback) { reply(callback, false); },
    signBotSignature: function(body) {
      if (body && body.length > 5) reply(body[5], '');
    }
  };
  // Re-themes as soon as the parser reaches a theme-color, and when a page
  // changes it later, instead of waiting for the load to finish. Only <head>
  // is watched; the whole document only until <head> exists.
  var themeColors = '';
  function check() {
    var metas = document.head.querySelectorAll('meta[name="theme-color"]');
    var value = '';
    for (var i = 0; i < metas.length; i++) {
      value += metas[i].getAttribute('content') + '|' +
          metas[i].getAttribute('media') + ';';
    }
    if (value === themeColors) return;
    themeColors = value;
    post('reloadTheme');
  }
  // A theme-color may depend on prefers-color-scheme, which follows
  // setBrightness without touching the DOM.
  var scheme = window.matchMedia('(prefers-color-scheme: dark)');
  function onScheme() { post('reloadTheme'); }
  if (scheme.addEventListener) {
    scheme.addEventListener('change', onScheme);
  } else {
    scheme.addListener(onScheme);
  }
  var observer = new MutationObserver(check);
  function watchHead() {
    if (!document.head) return false;
    observer.observe(document.head, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['name', 'content', 'media']
    });
    // The parser may have added the theme-color along with <head>.
    check();
    return true;
  }
  if (!watchHead()) {
    var waiter = new MutationObserver(function() {
      if (watchHead()) waiter.disconnect();
    });
    waiter.observe(document, { childList: true, subtree: true });
  }
})();
''';
