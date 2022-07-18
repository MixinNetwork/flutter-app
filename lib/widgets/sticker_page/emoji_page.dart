import 'dart:math' as math;

import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../account/account_key_value.dart';
import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../clamping_custom_scroll_view/scroller_scroll_controller.dart';
import '../interactive_decorated_box.dart';

class EmojiSelectedGroupIndexCubit extends Cubit<int> {
  EmojiSelectedGroupIndexCubit() : super(1);

  void setIndex(int index) => emit(index);
}

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
              : _EmojiGroupPage(
                  groups: const [
                    [EmojiGroup.smileysEmotion, EmojiGroup.peopleBody],
                    [EmojiGroup.animalsNature],
                    [EmojiGroup.foodDrink],
                    [EmojiGroup.travelPlaces],
                    [EmojiGroup.activities],
                    [EmojiGroup.objects],
                    [EmojiGroup.symbols],
                    [EmojiGroup.flags],
                  ][selectedIndex - 1],
                ),
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
    final emojis = useState(AccountKeyValue.instance.recentUsedEmoji);
    return _EmojiGridView(emojis: emojis.value);
  }
}

class _EmojiGroupPage extends HookWidget {
  const _EmojiGroupPage({required this.groups});

  final List<EmojiGroup> groups;

  @override
  Widget build(BuildContext context) {
    final emojis = useMemoized(
      () => groups.expand<Emoji>(Emoji.byGroup).map((e) => e.char).toList(),
      [groups],
    );
    return _EmojiGridView(emojis: emojis);
  }
}

class _EmojiGridView extends HookWidget {
  const _EmojiGridView({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(ScrollerScrollController.new);
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 11,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
      ),
      itemCount: emojis.length,
      itemBuilder: (BuildContext context, int index) => _EmojiItem(
        emoji: emojis[index],
      ),
    );
  }
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
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20, height: 1),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
