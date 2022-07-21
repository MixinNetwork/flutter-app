import 'dart:io';
import 'dart:math' as math;

import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../account/account_key_value.dart';
import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../clamping_custom_scroll_view/scroller_scroll_controller.dart';
import '../interactive_decorated_box.dart';

class EmojiSelectedGroupIndexCubit extends Cubit<int> {
  EmojiSelectedGroupIndexCubit() : super(1);

  void setIndex(int index) => emit(index);
}

const _emojiGroups = [
  [EmojiGroup.smileysEmotion, EmojiGroup.peopleBody],
  [EmojiGroup.animalsNature],
  [EmojiGroup.foodDrink],
  [EmojiGroup.travelPlaces],
  [EmojiGroup.activities],
  [EmojiGroup.objects],
  [EmojiGroup.symbols],
  [EmojiGroup.flags],
];

// ignore: avoid-non-ascii-symbols
const macOSIgnoreEmoji = {'☺️', '☹️'};

final _groupedEmojis = _emojiGroups
    .map(
      (group) => group
          .expand(Emoji.byGroup)
          .where((e) => !Platform.isMacOS || !macOSIgnoreEmoji.contains(e.char))
          .map((emoji) => emoji.char)
          .toList(),
    )
    .toList();

class EmojiPage extends HookWidget {
  const EmojiPage({super.key});

  @override
  Widget build(BuildContext context) {
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

    var selectedIndex = context.watch<EmojiSelectedGroupIndexCubit>().state;

    useEffect(() {
      assert(selectedIndex >= 0 && selectedIndex < emojiGroupIcon.length,
          'selectedIndex must be in range [0, ${emojiGroupIcon.length - 1}]');
      if (selectedIndex < 0 || selectedIndex >= emojiGroupIcon.length) {
        selectedIndex = 0;
      }
    }, [selectedIndex]);

    assert(
      _emojiGroups.length == _groupedEmojis.length,
      '_emojiGroups and _groupedEmojis must be same length',
    );

    return Column(
      children: [
        _EmojiGroupHeader(
          selectedIndex: selectedIndex,
          icons: emojiGroupIcon,
          onTap: (index) {
            context.read<EmojiSelectedGroupIndexCubit>().setIndex(index);
          },
        ),
        Divider(
          color: context.theme.divider,
          height: 1,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: selectedIndex == 0
              ? const _RecentEmojiGroupPage()
              : _AllEmojisPage(selectedGroupIndex: selectedIndex - 1),
        )
      ],
    );
  }
}

class _EmojiGroupHeader extends StatelessWidget {
  const _EmojiGroupHeader({
    required this.icons,
    required this.onTap,
    required this.selectedIndex,
  });

  final List<String> icons;
  final void Function(int index) onTap;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          children: [
            for (var i = 0; i < icons.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _EmojiGroupIcon(
                  icon: icons[i],
                  onTap: () => onTap(i),
                  index: i,
                  selectedIndex: selectedIndex,
                ),
              ),
          ],
        ),
      );
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
            width: 20,
            height: 20,
            color: selectedIndex == index
                ? context.theme.accent
                : context.theme.secondaryText,
          ),
        ),
      );
}

class _RecentEmojiGroupPage extends HookWidget {
  const _RecentEmojiGroupPage();

  @override
  Widget build(BuildContext context) {
    final emojis =
        useMemoized(() => AccountKeyValue.instance.recentUsedEmoji.chunked(11));
    final controller = useMemoized(ScrollerScrollController.new);
    return ListView.builder(
      itemExtent: _emojiItemExtent,
      controller: controller,
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        assert(index < emojis.length,
            'index must be in range [0, ${emojis.length - 1}]');
        if (index >= emojis.length) {
          return const SizedBox();
        }
        return _EmojiLine(emojis: emojis[index]);
      },
    );
  }
}

const _emojiItemExtent = 34.0;

class _AllEmojisPage extends HookWidget {
  _AllEmojisPage({
    required this.selectedGroupIndex,
  }) : assert(
            selectedGroupIndex >= 0 &&
                selectedGroupIndex < _groupedEmojis.length,
            'selectedGroupIndex must be in range [0, ${_groupedEmojis.length - 1}]');

  final int selectedGroupIndex;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(ScrollerScrollController.new);

    final groupedEmojiLine = useMemoized(
      () => List<List<List<String>>>.unmodifiable(
          _groupedEmojis.map((e) => e.chunked(11))),
    );

    final groupOffset = useMemoized(() {
      final array = List<double>.filled(_emojiGroups.length, 0);
      for (var i = 1; i < _emojiGroups.length; i++) {
        array[i] = array[i - 1] +
            (groupedEmojiLine[i - 1].length + 1 /* header */) *
                _emojiItemExtent;
      }
      return array;
    });

    final itemCount = useMemoized(
      () =>
          groupedEmojiLine.fold<int>(
              0, (previousValue, element) => previousValue + element.length) +
          groupedEmojiLine.length,
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
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        controller.jumpTo(groupOffset[selectedGroupIndex]);
      });
    }, [selectedGroupIndex]);

    useEffect(() {
      void onScroll() {
        d('scroll ${controller.offset}');
      }

      controller.addListener(onScroll);
      return () {
        controller.removeListener(onScroll);
      };
    }, [controller]);

    return ListView.builder(
      controller: controller,
      itemExtent: _emojiItemExtent,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        var inGroupIndex = index;
        for (var i = 0; i < groupedEmojiLine.length; i++) {
          if (inGroupIndex <= groupedEmojiLine[i].length) {
            if (inGroupIndex == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 20),
                child: SizedBox(
                    height: 24,
                    child: Text(
                      groupTitles[i],
                      style: TextStyle(
                        fontSize: 14,
                        color: context.theme.secondaryText,
                      ),
                    )),
              );
            } else {
              return _EmojiLine(
                emojis: groupedEmojiLine[i][inGroupIndex - 1],
              );
            }
          }
          inGroupIndex -= groupedEmojiLine[i].length + 1;
        }
        assert(false, 'unreachable: $index');
        return const SizedBox();
      },
    );
  }
}

class _EmojiLine extends StatelessWidget {
  const _EmojiLine({required this.emojis}) : assert(emojis.length <= 11);

  final List<String> emojis;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
        child: SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final emoji in emojis) _EmojiItem(emoji: emoji),
              for (var i = emojis.length; i < 11; i++)
                const SizedBox.square(dimension: 24),
            ],
          ),
        ),
      );
}

class _EmojiItem extends StatelessWidget {
  const _EmojiItem({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox(
        onTap: () {
          final textController = context.read<TextEditingController>();
          final textEditingValue = textController.value;
          final selection = textEditingValue.selection;
          if (!selection.isValid) {
            textController.text = '${textEditingValue.text}$emoji';
          } else {
            final int lastSelectionIndex =
                math.max(selection.baseOffset, selection.extentOffset);
            final collapsedTextEditingValue = textEditingValue.copyWith(
              selection: TextSelection.collapsed(offset: lastSelectionIndex),
            );
            textController.value =
                collapsedTextEditingValue.replaced(selection, emoji);
          }
          AccountKeyValue.instance.onEmojiUsed(emoji);
        },
        child: SizedBox.square(
          dimension: 24,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20, height: 1),
            textAlign: TextAlign.center,
          ),
        ),
      );
}
