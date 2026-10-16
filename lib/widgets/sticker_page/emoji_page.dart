import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

import '../../account/account_key_value.dart';
import '../../constants/resources.dart';
import '../../utils/emoji.dart';
import '../../utils/extension/extension.dart';
import '../interactive_decorated_box.dart';

final _emojiScrollOffsetProvider = StateProvider<double>((ref) => 0);

const emojiGroups = [
  [EmojiGroup.smileysEmotion, EmojiGroup.peopleBody],
  [EmojiGroup.animalsNature],
  [EmojiGroup.foodDrink],
  [EmojiGroup.travelPlaces],
  [EmojiGroup.activities],
  [EmojiGroup.objects],
  [EmojiGroup.symbols],
  [EmojiGroup.flags],
];

final _emojiStyle = TextStyle(
  fontSize: 26,
  height: 1,
  fontFamily: kEmojiFontFamily,
  inherit: false,
);
const _emojiStrutStyle = StrutStyle(height: 1);

List<String> _groupEmojis(List<EmojiGroup> group) => group
    .expand(Emoji.byGroup)
    .where((e) => !e.modifiable)
    .map((emoji) => emoji.char)
    .toList();

/// Emoji drawn into images once, as the Telegram apps draw their emoji panels.
///
/// Laying out a color emoji costs about 0.1 ms, and the first time each one
/// is drawn its glyph goes into the raster thread's glyph atlas. A panel that
/// scrolls through hundreds of new emoji did both every frame. An image costs
/// that once, and the panel then only draws images.
class _EmojiImages extends ChangeNotifier {
  _EmojiImages._();

  static final instance = _EmojiImages._();

  // A batch leaves the rest of a 8.3 ms frame at 120 Hz to the frame.
  static const _batchBudget = Duration(milliseconds: 2);

  // The raster thread decodes the color glyph of each image, about 1 ms per
  // emoji on macOS, so a batch stays small and the next one waits for it.
  // Twenty images at once held the raster thread for 30 ms.
  static const _batchSize = 3;

  final _images = <String, ui.Image>{};
  final _pending = <String>{};
  final _rendering = <String>{};
  double _pixelRatio = 0;
  var _scheduled = false;
  var _largestBatch = 0;

  ui.Image? operator [](String emoji) => _images[emoji];

  /// Renders the images of [emojis] that are missing.
  void request(Iterable<String> emojis, double pixelRatio) {
    if (pixelRatio != _pixelRatio) {
      for (final image in _images.values) {
        image.dispose();
      }
      _images.clear();
      _pixelRatio = pixelRatio;
    }
    for (final emoji in emojis) {
      if (!_images.containsKey(emoji) && !_rendering.contains(emoji)) {
        _pending.add(emoji);
      }
    }
    _schedule();
  }

  // Animation priority: an idle task waits as long as any animation runs, and
  // the scheduler polls it on every event loop turn meanwhile. A batch is
  // short enough to run between frames.
  void _schedule() {
    if (_scheduled || _rendering.isNotEmpty || _pending.isEmpty) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleTask(() {
      _scheduled = false;
      _renderBatch();
    }, Priority.animation);
  }

  void _renderBatch() {
    final pixelRatio = _pixelRatio;
    final watch = Stopwatch()..start();
    final renders = <Future<void>>[];
    while (_pending.isNotEmpty &&
        renders.length < _batchSize &&
        watch.elapsed < _batchBudget) {
      final emoji = _pending.first;
      _pending.remove(emoji);
      _rendering.add(emoji);
      renders.add(_render(emoji, pixelRatio));
    }
    _largestBatch = math.max(_largestBatch, renders.length);
    unawaited(
      Future.wait(renders).then((_) {
        notifyListeners();
        _schedule();
      }),
    );
  }

  Future<void> _render(String emoji, double pixelRatio) async {
    final painter = TextPainter(
      text: TextSpan(text: emoji, style: _emojiStyle),
      strutStyle: _emojiStrutStyle,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final size = painter.size;
    final recorder = ui.PictureRecorder();
    painter
      ..paint(Canvas(recorder)..scale(pixelRatio), Offset.zero)
      ..dispose();
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(
        math.max(1, (size.width * pixelRatio).ceil()),
        math.max(1, (size.height * pixelRatio).ceil()),
      );
      if (pixelRatio == _pixelRatio) {
        _images[emoji] = image;
      } else {
        image.dispose();
      }
    } finally {
      picture.dispose();
      _rendering.remove(emoji);
    }
  }
}

@visibleForTesting
bool emojiImageReady(String emoji) => _EmojiImages.instance[emoji] != null;

@visibleForTesting
int get largestEmojiImageBatch => _EmojiImages.instance._largestBatch;

var _emojiPageWarmed = false;

/// Renders the images of the emoji that the panel shows first, so the first
/// open of the panel finds them ready. It starts a little later, after the
/// chat that mounted the composer has built its rows.
void warmEmojiPage(double pixelRatio) {
  if (_emojiPageWarmed) return;
  _emojiPageWarmed = true;
  Timer(
    const Duration(seconds: 2),
    () => _EmojiImages.instance.request(
      [
        ...AccountKeyValue.instance.recentUsedEmoji,
        ..._groupEmojis(emojiGroups.first),
      ].take(100),
      pixelRatio,
    ),
  );
}

class EmojiPage extends StatelessWidget {
  const EmojiPage({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        _EmojiPageBody(layoutWidth: constraints.maxWidth),
  );
}

class _EmojiPageBody extends HookConsumerWidget {
  const _EmojiPageBody({required this.layoutWidth});

  final double layoutWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const emojiGroupIcon = [
      Resources.assetsImagesEmojiRecentSvg,
      Resources.assetsImagesEmojiFaceSvg,
      Resources.assetsImagesEmojiAnimalSvg,
      Resources.assetsImagesEmojiFoodSvg,
      Resources.assetsImagesEmojiTravelSvg,
      Resources.assetsImagesEmojiSportsSvg,
      Resources.assetsImagesEmojiObjectsSvg,
      Resources.assetsImagesEmojiSymbolSvg,
      Resources.assetsImagesEmojiFlagsSvg,
    ];

    final offset = ref.watch(_emojiScrollOffsetProvider);

    final emojiLineStride = useRef(8);

    useEffect(() {
      for (var stride = 10; stride >= 8; stride--) {
        final emojiItemSize = (layoutWidth - 14 * 2) / stride;
        if (emojiItemSize >= 40) {
          emojiLineStride.value = stride;
          break;
        }
      }
    }, [layoutWidth]);

    final recentUsedEmoji = useMemoized(
      () => AccountKeyValue.instance.recentUsedEmoji,
    );

    final groupedEmojis = useMemoized(
      () => [recentUsedEmoji, ...emojiGroups.map(_groupEmojis)],
      [recentUsedEmoji],
    );

    final groupOffset = useMemoized(() {
      final array = List<double>.filled(groupedEmojis.length, 0);
      for (var i = 1; i < groupedEmojis.length; i++) {
        final emojiLineCount =
            (groupedEmojis[i - 1].length / emojiLineStride.value).ceil();
        final emojiItemSize = (layoutWidth - 14 * 2) / emojiLineStride.value;
        final headerHeight = i == 1 ? 0 : 40;
        array[i] = array[i - 1] + emojiLineCount * emojiItemSize + headerHeight;
      }
      return array;
    }, [emojiLineStride.value, layoutWidth, groupedEmojis]);

    final selectedIndex = useMemoized(() {
      for (var i = groupOffset.length - 1; i >= 0; i--) {
        if (groupOffset[i] <= offset) {
          return i;
        }
      }
      return 0;
    }, [offset]);

    final emojiOffsetController = useStreamController<double>();
    final emojiOffsetStream = useMemoized(() => emojiOffsetController.stream);

    return Column(
      children: [
        _EmojiGroupHeader(
          selectedIndex: selectedIndex,
          icons: emojiGroupIcon,
          onTap: (index) {
            ref.read(_emojiScrollOffsetProvider.notifier).state =
                groupOffset[index];
            emojiOffsetController.add(groupOffset[index]);
          },
        ),
        Divider(color: context.theme.divider, height: 1),
        const SizedBox(height: 8),
        Expanded(
          child: _AllEmojisPage(
            initialOffset: offset,
            offsetStream: emojiOffsetStream,
            emojiLineStride: emojiLineStride.value,
            groupedEmojis: groupedEmojis,
          ),
        ),
      ],
    );
  }
}

class _EmojiGroupHeader extends HookConsumerWidget {
  const _EmojiGroupHeader({
    required this.icons,
    required this.onTap,
    required this.selectedIndex,
  });

  final List<String> icons;
  final void Function(int index) onTap;
  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: icons.length);
    useEffect(() {
      tabController.index = selectedIndex;
    }, [selectedIndex]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: TabBar(
          controller: tabController,
          isScrollable: true,
          labelPadding: EdgeInsets.zero,
          indicator: const BoxDecoration(color: Colors.transparent),
          dividerColor: Colors.transparent,
          tabAlignment: TabAlignment.start,
          tabs: List.generate(
            icons.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _EmojiGroupIcon(
                icon: icons[index],
                onTap: () => onTap(index),
                index: index,
                selectedIndex: selectedIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiGroupIcon extends StatelessWidget {
  const _EmojiGroupIcon({
    required this.index,
    required this.onTap,
    required this.icon,
    required this.selectedIndex,
  });

  final int index;
  final VoidCallback onTap;
  final String icon;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox(
    onTap: onTap,
    hoveringDecoration: BoxDecoration(
      color: context.theme.sidebarSelected,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: SvgPicture.asset(
        icon,
        renderingStrategy: RenderingStrategy.raster,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          selectedIndex == index
              ? context.theme.accent
              : context.theme.secondaryText,
          BlendMode.srcIn,
        ),
      ),
    ),
  );
}

class _AllEmojisPage extends HookConsumerWidget {
  const _AllEmojisPage({
    required this.initialOffset,
    required this.offsetStream,
    required this.emojiLineStride,
    required this.groupedEmojis,
  });

  final double initialOffset;
  final Stream<double> offsetStream;
  final int emojiLineStride;
  final List<List<String>> groupedEmojis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(
      () => ScrollController(initialScrollOffset: initialOffset),
    );

    final groupTitles = [
      context.l10n.smileysAndPeople,
      context.l10n.animalsAndNature,
      context.l10n.foodAndDrink,
      context.l10n.travelAndPlaces,
      context.l10n.activity,
      context.l10n.objects,
      context.l10n.symbols,
      context.l10n.flags,
    ];

    useEffect(() {
      void onScroll() {
        ref.read(_emojiScrollOffsetProvider.notifier).state = controller.offset;
      }

      controller.addListener(onScroll);
      return () {
        controller.removeListener(onScroll);
      };
    }, [controller]);

    useEffect(() => offsetStream.listen(controller.jumpTo).cancel, [
      offsetStream,
    ]);

    return CustomScrollView(
      controller: controller,
      slivers: [
        for (var i = 0; i < groupedEmojis.length; i++) ...[
          if (i > 0)
            SliverToBoxAdapter(
              child: _EmojiGroupTitle(title: groupTitles[i - 1]),
            ),
          if (groupedEmojis[i].isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) => SliverFixedExtentList(
                  itemExtent: constraints.crossAxisExtent / emojiLineStride,
                  delegate: SliverChildBuilderDelegate(
                    (context, row) => _EmojiRow(
                      emojis: groupedEmojis[i]
                          .skip(row * emojiLineStride)
                          .take(emojiLineStride)
                          .toList(),
                      columns: emojiLineStride,
                    ),
                    childCount: (groupedEmojis[i].length / emojiLineStride)
                        .ceil(),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EmojiGroupTitle extends StatelessWidget {
  const _EmojiGroupTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Padding(
      padding: const EdgeInsets.only(left: 20, top: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, color: context.theme.secondaryText),
      ),
    ),
  );
}

void _insertEmoji(BuildContext context, String emoji) {
  final textController = context.read<TextEditingController>();
  final textEditingValue = textController.value;
  final selection = textEditingValue.selection;
  if (!selection.isValid) {
    textController.text = '${textEditingValue.text}$emoji';
  } else {
    final int lastSelectionIndex = math.max(
      selection.baseOffset,
      selection.extentOffset,
    );
    final collapsedTextEditingValue = textEditingValue.copyWith(
      selection: TextSelection.collapsed(offset: lastSelectionIndex),
    );
    textController.value = collapsedTextEditingValue.replaced(
      selection,
      emoji,
    );
  }
  AccountKeyValue.instance.onEmojiUsed(emoji);
}

/// One line of the emoji grid, painted as one surface from emoji images.
class _EmojiRow extends StatefulWidget {
  const _EmojiRow({required this.emojis, required this.columns});

  final List<String> emojis;
  final int columns;

  @override
  State<_EmojiRow> createState() => _EmojiRowState();
}

class _EmojiRowState extends State<_EmojiRow> with TickerProviderStateMixin {
  // The hover fades of InteractiveDecoratedBox, which each cell used.
  AnimationController? _fadeIn;
  AnimationController? _fadeOut;
  int? _hovered;
  int? _leaving;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestImages();
  }

  @override
  void didUpdateWidget(covariant _EmojiRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emojis != widget.emojis) _requestImages();
  }

  void _requestImages() => _EmojiImages.instance.request(
    widget.emojis,
    MediaQuery.devicePixelRatioOf(context),
  );

  @override
  void dispose() {
    _fadeIn?.dispose();
    _fadeOut?.dispose();
    super.dispose();
  }

  int? _cellAt(Offset position) {
    final index = position.dx * widget.columns ~/ context.size!.width;
    return index >= 0 && index < widget.emojis.length ? index : null;
  }

  void _hover(int? index) {
    if (index == _hovered) return;
    final fadeIn = _fadeIn ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    final fadeOut = _fadeOut ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );
    setState(() {
      if (_hovered != null) {
        _leaving = _hovered;
        fadeOut
          ..value = fadeIn.value
          ..reverse(from: fadeIn.value);
      }
      _hovered = index;
      if (index != null) fadeIn.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onHover: (event) => _hover(_cellAt(event.localPosition)),
    onExit: (_) => _hover(null),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final index = _cellAt(details.localPosition);
        if (index != null) _insertEmoji(context, widget.emojis[index]);
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: _EmojiRowPainter(
          emojis: widget.emojis,
          columns: widget.columns,
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
          hoverColor: context.dynamicColor(
            const Color.fromRGBO(229, 231, 235, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
          ),
          hovered: _hovered,
          leaving: _leaving,
          fadeIn: _fadeIn,
          fadeOut: _fadeOut,
          onTap: (emoji) => _insertEmoji(context, emoji),
        ),
      ),
    ),
  );
}

class _EmojiRowPainter extends CustomPainter {
  _EmojiRowPainter({
    required this.emojis,
    required this.columns,
    required this.pixelRatio,
    required this.hoverColor,
    required this.hovered,
    required this.leaving,
    required this.fadeIn,
    required this.fadeOut,
    required this.onTap,
  }) : super(
         repaint: Listenable.merge([_EmojiImages.instance, fadeIn, fadeOut]),
       );

  final List<String> emojis;
  final int columns;
  final double pixelRatio;
  final Color hoverColor;
  final int? hovered;
  final int? leaving;
  final Animation<double>? fadeIn;
  final Animation<double>? fadeOut;
  final void Function(String emoji) onTap;

  Rect _cell(Size size, int index) {
    final width = size.width / columns;
    return Rect.fromLTWH(width * index, 0, width, size.height);
  }

  void _paintHover(Canvas canvas, Size size, int? index, double? opacity) {
    if (index == null || opacity == null || opacity <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        _cell(size, index).deflate(2),
        const Radius.circular(8),
      ),
      Paint()..color = hoverColor.withValues(alpha: hoverColor.a * opacity),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintHover(canvas, size, leaving, fadeOut?.value);
    _paintHover(canvas, size, hovered, fadeIn?.value);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    for (var i = 0; i < emojis.length; i++) {
      final image = _EmojiImages.instance[emojis[i]];
      if (image == null) continue;
      final imageSize = Size(
        image.width / pixelRatio,
        image.height / pixelRatio,
      );
      final cell = _cell(size, i);
      // A sequence the emoji font lacks draws as several glyphs; keep it in
      // its cell.
      final fitted = applyBoxFit(
        BoxFit.scaleDown,
        imageSize,
        cell.size,
      ).destination;
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        Alignment.center.inscribe(fitted, cell),
        paint,
      );
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (var i = 0; i < emojis.length; i++)
          CustomPainterSemantics(
            rect: _cell(size, i),
            properties: SemanticsProperties(
              label: emojis[i],
              button: true,
              textDirection: TextDirection.ltr,
              onTap: () => onTap(emojis[i]),
            ),
          ),
      ];

  @override
  bool shouldRepaint(_EmojiRowPainter oldDelegate) =>
      oldDelegate.emojis != emojis ||
      oldDelegate.columns != columns ||
      oldDelegate.pixelRatio != pixelRatio ||
      oldDelegate.hoverColor != hoverColor ||
      oldDelegate.hovered != hovered ||
      oldDelegate.leaving != leaving;

  @override
  bool shouldRebuildSemantics(_EmojiRowPainter oldDelegate) =>
      oldDelegate.emojis != emojis || oldDelegate.columns != columns;
}
