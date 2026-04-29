import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_markdown_widget/mixin_markdown_widget.dart';

import '../ui/provider/setting_provider.dart';
import '../utils/extension/extension.dart';
import '../utils/uri_utils.dart';
import 'message/message_style.dart';
import 'mixin_image.dart';

const _kMarkdownControllerCacheLimit = 120;
const _kMarkdownWarmupPerFrame = 2;

String buildMarkdownCacheKey({
  required String namespace,
  required String id,
}) => '$namespace:$id';

final markdownControllerCache = MarkdownControllerCache();

class MarkdownControllerCache {
  final _entries = <String, _MarkdownCacheEntry>{};
  final _pending = <String, Completer<void>>{};
  final _queuedKeys = <String>{};
  final _warmupQueue = ListQueue<({String key, String data})>();

  bool _warmupScheduled = false;

  MarkdownController? acquire(
    String key,
    String data, {
    bool streaming = false,
  }) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (entry.data != data) {
      _updateEntryData(entry, data, streaming: streaming);
    } else if (!streaming) {
      entry.controller.commitStream();
    }
    _touch(key, entry);
    entry.retainCount += 1;
    return entry.controller;
  }

  void release(String key, MarkdownController controller) {
    final entry = _entries[key];
    if (entry == null || !identical(entry.controller, controller)) return;
    if (entry.retainCount > 0) {
      entry.retainCount -= 1;
    }
  }

  Future<void> warmup(String key, String data) {
    final entry = _entries[key];
    if (entry != null) {
      if (entry.data == data) {
        _touch(key, entry);
        entry.controller.commitStream();
        return Future.value();
      }
      _updateEntryData(entry, data, streaming: false);
      _touch(key, entry);
      return Future.value();
    }

    final pending = _pending[key];
    if (pending != null) return pending.future;

    final completer = Completer<void>();
    _pending[key] = completer;
    if (_queuedKeys.add(key)) {
      _warmupQueue.add((key: key, data: data));
      _scheduleWarmup();
    }
    return completer.future;
  }

  void warmupAll(Iterable<({String key, String data})> entries) {
    for (final entry in entries) {
      unawaited(warmup(entry.key, entry.data));
    }
  }

  void _scheduleWarmup() {
    if (_warmupScheduled) return;
    _warmupScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _warmupScheduled = false;
      _drainWarmupQueue();
    });
  }

  void _drainWarmupQueue() {
    var count = 0;
    while (_warmupQueue.isNotEmpty && count < _kMarkdownWarmupPerFrame) {
      final task = _warmupQueue.removeFirst();
      _queuedKeys.remove(task.key);
      final completer = _pending.remove(task.key);

      try {
        final existing = _entries[task.key];
        if (existing != null) {
          if (existing.data != task.data) {
            _updateEntryData(existing, task.data, streaming: false);
          } else {
            existing.controller.commitStream();
          }
          _touch(task.key, existing);
        } else {
          _entries[task.key] = _MarkdownCacheEntry(
            data: task.data,
            controller: MarkdownController(data: task.data),
          );
          _evictIfNeeded();
        }
        completer?.complete();
      } catch (error, stackTrace) {
        completer?.completeError(error, stackTrace);
      }
      count += 1;
    }

    if (_warmupQueue.isNotEmpty) {
      _scheduleWarmup();
    }
  }

  void _touch(String key, _MarkdownCacheEntry entry) {
    _entries.remove(key);
    _entries[key] = entry;
  }

  void _evictIfNeeded() {
    while (_entries.length > _kMarkdownControllerCacheLimit) {
      String? keyToRemove;
      _MarkdownCacheEntry? entryToRemove;
      for (final entry in _entries.entries) {
        if (entry.value.retainCount == 0) {
          keyToRemove = entry.key;
          entryToRemove = entry.value;
          break;
        }
      }
      if (keyToRemove == null || entryToRemove == null) {
        return;
      }
      _removeEntry(keyToRemove, entryToRemove);
    }
  }

  void _removeEntry(String key, _MarkdownCacheEntry entry) {
    _entries.remove(key);
    entry.controller.dispose();
  }

  void _updateEntryData(
    _MarkdownCacheEntry entry,
    String data, {
    required bool streaming,
  }) {
    final previousData = entry.data;
    entry.data = data;
    if (streaming && data.startsWith(previousData)) {
      entry.controller.appendChunk(data.substring(previousData.length));
      return;
    }
    entry.controller.setData(data);
    if (!streaming) {
      entry.controller.commitStream();
    }
  }
}

class _MarkdownCacheEntry {
  _MarkdownCacheEntry({
    required this.data,
    required this.controller,
  });

  String data;
  final MarkdownController controller;
  int retainCount = 0;
}

class MarkdownColumn extends HookConsumerWidget {
  const MarkdownColumn({
    required this.data,
    super.key,
    this.selectable = false,
    this.cacheKey,
    this.streaming = false,
  });

  final String data;
  final bool selectable;
  final String? cacheKey;
  final bool streaming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatFontSizeDelta = ref.watch(
      settingProvider.select((value) => value.chatFontSizeDelta),
    );

    return ClipRect(
      child: _MarkdownView(
        data: data,
        cacheKey: cacheKey,
        streaming: streaming,
        useColumn: true,
        selectable: selectable,
        contextMenuBuilder: (_, _, _, _) => const SizedBox.shrink(),
        padding: EdgeInsets.zero,
        theme: _createMarkdownTheme(context, chatFontSizeDelta),
        imageBuilder: _buildMarkdownImage,
        onTapLink: (destination, title, label) {
          if (destination.isEmpty) return;
          openUri(context, destination);
        },
      ),
    );
  }
}

class Markdown extends HookConsumerWidget {
  const Markdown({
    required this.data,
    super.key,
    this.padding = EdgeInsets.zero,
    this.physics,
    this.cacheKey,
    this.streaming = false,
  });

  final String data;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final String? cacheKey;
  final bool streaming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatFontSizeDelta = ref.watch(
      settingProvider.select((value) => value.chatFontSizeDelta),
    );

    return _MarkdownView(
      data: data,
      cacheKey: cacheKey,
      streaming: streaming,
      padding: padding,
      physics: physics,
      theme: _createMarkdownTheme(context, chatFontSizeDelta),
      imageBuilder: _buildMarkdownImage,
      onTapLink: (destination, title, label) {
        if (destination.isEmpty) return;
        openUri(context, destination);
      },
    );
  }
}

class _MarkdownView extends HookWidget {
  const _MarkdownView({
    required this.data,
    required this.theme,
    required this.imageBuilder,
    required this.onTapLink,
    this.cacheKey,
    this.padding,
    this.physics,
    this.streaming = false,
    this.useColumn = false,
    this.selectable = true,
    this.contextMenuBuilder,
  });

  final String data;
  final String? cacheKey;
  final bool streaming;
  final MarkdownThemeData theme;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool useColumn;
  final bool selectable;
  final MarkdownImageBuilder imageBuilder;
  final MarkdownTapLinkCallback onTapLink;
  final MarkdownContextMenuBuilder? contextMenuBuilder;

  @override
  Widget build(BuildContext context) {
    if (cacheKey == null) {
      return _buildMarkdownWidget(data: data);
    }

    final controller =
        useState<({String key, String data, MarkdownController controller})?>(
          null,
        );

    useEffect(() {
      var disposed = false;
      MarkdownController? retained;

      bool bindCachedController() {
        final cached = markdownControllerCache.acquire(
          cacheKey!,
          data,
          streaming: streaming,
        );
        if (cached == null || disposed) return false;
        retained = cached;
        controller.value = (key: cacheKey!, data: data, controller: cached);
        return true;
      }

      if (!bindCachedController()) {
        unawaited(
          markdownControllerCache.warmup(cacheKey!, data).then((_) {
            if (disposed) return;
            bindCachedController();
          }),
        );
      }

      return () {
        disposed = true;
        final current = retained;
        if (current != null) {
          markdownControllerCache.release(cacheKey!, current);
        }
      };
    }, [cacheKey, data, streaming]);

    final cachedController = controller.value;
    if (cachedController != null &&
        cachedController.key == cacheKey &&
        cachedController.data == data) {
      return _buildMarkdownWidget(controller: cachedController.controller);
    }

    return _MarkdownFallback(
      data: data,
      theme: theme,
      padding: padding,
    );
  }

  Widget _buildMarkdownWidget({
    String? data,
    MarkdownController? controller,
  }) => MarkdownWidget(
    data: data,
    controller: controller,
    padding: padding,
    physics: physics,
    useColumn: useColumn,
    selectable: selectable,
    contextMenuBuilder: contextMenuBuilder,
    theme: theme,
    imageBuilder: imageBuilder,
    onTapLink: onTapLink,
  );
}

class _MarkdownFallback extends StatelessWidget {
  const _MarkdownFallback({
    required this.data,
    required this.theme,
    this.padding,
  });

  final String data;
  final MarkdownThemeData theme;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? EdgeInsets.zero;
    return Padding(
      padding: effectivePadding,
      child: Text(
        data,
        style: theme.bodyStyle,
      ),
    );
  }
}

Widget _buildMarkdownImage(
  BuildContext context,
  ImageBlock block,
  MarkdownThemeData theme,
) {
  final uri = Uri.tryParse(block.url);
  final width = _tryParseImageDimension(uri, 'w', 'width');
  final height = _tryParseImageDimension(uri, 'h', 'height');

  Widget errorBuilder(BuildContext context, Object error, StackTrace? stack) {
    final iconColor = theme.bodyStyle.color?.withValues(alpha: 0.72);
    if (width != null && height != null) {
      return Container(
        width: width,
        height: height,
        color: theme.imagePlaceholderBackgroundColor,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: theme.dividerColor),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.imagePlaceholderBackgroundColor,
        borderRadius: theme.imageBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              block.alt?.isNotEmpty == true ? block.alt! : 'Image',
              style: theme.bodyStyle.copyWith(color: iconColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  final image = _buildMixinImageForUrl(
    block.url,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );

  return ClipRRect(
    borderRadius: theme.imageBorderRadius,
    child: image,
  );
}

double? _tryParseImageDimension(Uri? uri, String shortKey, String fullKey) {
  if (uri == null) return null;
  final value = uri.queryParameters[shortKey] ?? uri.queryParameters[fullKey];
  return value == null ? null : double.tryParse(value);
}

Widget _buildMixinImageForUrl(
  String url, {
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  final uri = Uri.tryParse(url);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return MixinImage.network(
      url,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  if (uri != null && uri.scheme == 'file') {
    return MixinImage.file(
      File.fromUri(uri),
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  final file = File(url);
  if (file.isAbsolute) {
    return MixinImage.file(
      file,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  return MixinImage.asset(
    url,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}

MarkdownThemeData _createMarkdownTheme(
  BuildContext context,
  double chatFontSizeDelta,
) {
  final foreground = context.brightness == Brightness.dark
      ? MarkdownThemeForeground.dark
      : MarkdownThemeForeground.light;
  final base = MarkdownThemeData.themed(
    context,
    foreground: foreground,
  );
  final textColor = context.theme.text;
  final accentColor = context.theme.accent;
  final chatBodyFontSize =
      MessageStyle.defaultStyle.primaryFontSize + chatFontSizeDelta;
  final baseBodyFontSize = base.bodyStyle.fontSize ?? chatBodyFontSize;
  final fontSizeScale = baseBodyFontSize == 0
      ? 1.0
      : chatBodyFontSize / baseBodyFontSize;

  TextStyle applyTextColor(TextStyle style) => style.copyWith(color: textColor);
  TextStyle scaleFontSize(TextStyle style) {
    final fontSize = style.fontSize;
    if (fontSize == null) return style;
    return style.copyWith(fontSize: fontSize * fontSizeScale);
  }

  TextStyle applyTextStyle(TextStyle style) =>
      applyTextColor(scaleFontSize(style));

  return base.copyWith(
    bodyStyle: applyTextStyle(base.bodyStyle),
    quoteStyle: scaleFontSize(
      base.quoteStyle.copyWith(
        color: base.quoteStyle.color ?? textColor.withValues(alpha: 0.82),
      ),
    ),
    linkStyle: base.linkStyle.copyWith(
      color: accentColor,
      decorationColor: accentColor,
      fontSize:
          (base.linkStyle.fontSize ??
              base.bodyStyle.fontSize ??
              chatBodyFontSize) *
          fontSizeScale,
      decoration: .none,
    ),
    inlineCodeStyle: applyTextStyle(base.inlineCodeStyle),
    codeBlockStyle: applyTextStyle(base.codeBlockStyle),
    tableHeaderStyle: applyTextStyle(base.tableHeaderStyle),
    heading1Style: applyTextStyle(
      scaleFontSize(
        base.heading1Style.copyWith(
          height: 40 / 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    heading2Style: applyTextStyle(base.heading2Style),
    heading3Style: applyTextStyle(base.heading3Style),
    heading4Style: applyTextStyle(base.heading4Style),
    heading5Style: applyTextStyle(base.heading5Style),
    heading6Style: applyTextStyle(base.heading6Style),
    quoteBorderColor: accentColor.withValues(alpha: 0.4),
    selectionColor: accentColor.withValues(alpha: 0.24),
    showHeading1Divider: false,
    quoteBackgroundColor: Colors.transparent,
  );
}
