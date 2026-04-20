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
import 'mixin_image.dart';

const _kMarkdownControllerCacheLimit = 120;
const _kMarkdownWarmupPerFrame = 2;

String buildMarkdownCacheKey({
  required String namespace,
  required String id,
  required String data,
}) => '$namespace:$id:${data.hashCode}';

final markdownControllerCache = MarkdownControllerCache();

class MarkdownControllerCache {
  final _entries = <String, _MarkdownCacheEntry>{};
  final _pending = <String, Completer<void>>{};
  final _queuedKeys = <String>{};
  final _warmupQueue = ListQueue<({String key, String data})>();

  bool _warmupScheduled = false;

  MarkdownController? acquire(String key, String data) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (entry.data != data) {
      _removeEntry(key, entry);
      return null;
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
        return Future.value();
      }
      _removeEntry(key, entry);
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
        if (existing != null && existing.data == task.data) {
          _touch(task.key, existing);
        } else {
          if (existing != null) {
            _removeEntry(task.key, existing);
          }
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
}

class _MarkdownCacheEntry {
  _MarkdownCacheEntry({
    required this.data,
    required this.controller,
  });

  final String data;
  final MarkdownController controller;
  int retainCount = 0;
}

class MarkdownColumn extends HookConsumerWidget {
  const MarkdownColumn({
    required this.data,
    super.key,
    this.selectable = false,
    this.cacheKey,
  });

  final String data;
  final bool selectable;
  final String? cacheKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatFontSizeDelta = ref.watch(
      settingProvider.select((value) => value.chatFontSizeDelta),
    );

    return ClipRect(
      child: _MarkdownView(
        data: data,
        cacheKey: cacheKey,
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
  });

  final String data;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final String? cacheKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatFontSizeDelta = ref.watch(
      settingProvider.select((value) => value.chatFontSizeDelta),
    );

    return _MarkdownView(
      data: data,
      cacheKey: cacheKey,
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
    this.useColumn = false,
    this.selectable = true,
    this.contextMenuBuilder,
  });

  final String data;
  final String? cacheKey;
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

    final controller = useState<MarkdownController?>(null);

    useEffect(() {
      var disposed = false;
      MarkdownController? retained;

      void bindCachedController() {
        final cached = markdownControllerCache.acquire(cacheKey!, data);
        if (cached == null || disposed) return;
        retained = cached;
        controller.value = cached;
      }

      bindCachedController();
      if (controller.value == null) {
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
    }, [cacheKey, data]);

    final cachedController = controller.value;
    if (cachedController != null) {
      return _buildMarkdownWidget(controller: cachedController);
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
  final base = MarkdownThemeData.fallback(context);
  final textColor = context.theme.text;
  final accentColor = context.theme.accent;
  final codeBlockBackgroundColor = context.theme.chatBackground;

  TextStyle applyTextColor(TextStyle style) => style.copyWith(color: textColor);
  TextStyle applyFontSizeDelta(TextStyle style) {
    final fontSize = style.fontSize;
    if (fontSize == null) return style;
    return style.copyWith(fontSize: fontSize + chatFontSizeDelta);
  }

  TextStyle applyTextStyle(TextStyle style) =>
      applyTextColor(applyFontSizeDelta(style));

  return base.copyWith(
    bodyStyle: applyTextStyle(base.bodyStyle),
    quoteStyle: applyFontSizeDelta(
      base.quoteStyle.copyWith(
        color: textColor.withValues(alpha: 0.82),
      ),
    ),
    linkStyle: base.linkStyle.copyWith(
      color: accentColor,
      decorationColor: accentColor,
      fontSize:
          (base.linkStyle.fontSize ?? base.bodyStyle.fontSize ?? 16) +
          chatFontSizeDelta,
    ),
    inlineCodeStyle: applyTextStyle(base.inlineCodeStyle),
    codeBlockStyle: applyTextStyle(base.codeBlockStyle),
    codeBlockBackgroundColor: codeBlockBackgroundColor,
    inlineCodeBackgroundColor: codeBlockBackgroundColor,
    quoteBackgroundColor: codeBlockBackgroundColor,
    tableHeaderStyle: applyTextStyle(base.tableHeaderStyle),
    heading1Style: applyTextStyle(
      applyFontSizeDelta(
        base.heading1Style.copyWith(
          fontSize: 32,
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
  );
}
