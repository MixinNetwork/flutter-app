import 'dart:math' as math;

import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

class EmojiPage extends StatelessWidget {
  const EmojiPage({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder:
        (context, constraints) =>
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
      () => [
        recentUsedEmoji,
        ...emojiGroups.map(
          (group) =>
              group
                  .expand(Emoji.byGroup)
                  .where((e) => !e.modifiable)
                  .map((emoji) => emoji.char)
                  .toList(),
        ),
      ],
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
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _EmojiItem(emoji: groupedEmojis[i][index]),
                  childCount: groupedEmojis[i].length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: emojiLineStride,
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

class _EmojiItem extends StatelessWidget {
  const _EmojiItem({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(2),
    child: InteractiveDecoratedBox(
      onTap: () {
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
      },
      hoveringDecoration: BoxDecoration(
        color: context.dynamicColor(
          const Color.fromRGBO(229, 231, 235, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 26,
            height: 1,
            fontFamily: kEmojiFontFamily,
            inherit: false,
          ),
          strutStyle: const StrutStyle(height: 1),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
