import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../account/account_key_value.dart';
import '../../bloc/bloc_converter.dart';
import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../automatic_keep_alive_client_widget.dart';
import '../hover_overlay.dart';
import '../interactive_decorated_box.dart';
import 'bloc/cubit/sticker_albums_cubit.dart';
import 'bloc/cubit/sticker_cubit.dart';
import 'emoji_page.dart';
import 'giphy_page.dart';
import 'sticker_item.dart';
import 'sticker_store.dart';

enum PresetStickerGroup {
  store,
  emoji,
  recent,
  favorite,
  gif;
}

class StickerPage extends StatelessWidget {
  const StickerPage({
    required this.tabLength,
    super.key,
    required this.tabController,
    required this.presetStickerGroups,
  });

  final TabController tabController;
  final int tabLength;
  final List<PresetStickerGroup> presetStickerGroups;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(11)),
        child: Container(
          width: 464,
          height: 407,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(11)),
            color: context.dynamicColor(
              const Color.fromRGBO(255, 255, 255, 1),
              darkColor: const Color.fromRGBO(62, 65, 72, 1),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(11)),
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(
                      tabLength,
                      (index) {
                        if (index < presetStickerGroups.length) {
                          final preset = presetStickerGroups[index];
                          switch (preset) {
                            case PresetStickerGroup.store:
                              return _StickerStoreEmptyPage();
                            case PresetStickerGroup.emoji:
                              return const AutomaticKeepAliveClientWidget(
                                child: EmojiPage(),
                              );
                            case PresetStickerGroup.recent:
                              return _StickerAlbumPage(
                                getStickers: () => context.database.stickerDao
                                    .recentUsedStickers()
                                    .watchThrottle(kVerySlowThrottleDuration),
                                updateUsedAt: false,
                              );
                            case PresetStickerGroup.favorite:
                              return _StickerAlbumPage(
                                getStickers: () => context.database.stickerDao
                                    .personalStickers()
                                    .watchThrottle(kVerySlowThrottleDuration),
                                rightClickDelete: true,
                              );
                            case PresetStickerGroup.gif:
                              return const AutomaticKeepAliveClientWidget(
                                child: GiphyPage(),
                              );
                          }
                        }
                        return _StickerAlbumPage(
                          getStickers: () => context.database.stickerDao
                              .stickerByAlbumId(
                                  BlocProvider.of<StickerAlbumsCubit>(context)
                                      .state[index - presetStickerGroups.length]
                                      .albumId)
                              .watchThrottle(kVerySlowThrottleDuration),
                        );
                      },
                    ),
                  ),
                ),
                _StickerAlbumBar(
                  tabLength: tabLength,
                  tabController: tabController,
                  presetStickerGroups: presetStickerGroups,
                ),
              ],
            ),
          ),
        ),
      );
}

class _StickerAlbumPage extends HookWidget {
  const _StickerAlbumPage({
    required this.getStickers,
    this.updateUsedAt = true,
    this.rightClickDelete = false,
  });

  final Stream<List<Sticker>> Function() getStickers;

  final bool updateUsedAt;
  final bool rightClickDelete;

  @override
  Widget build(BuildContext context) {
    final stickerCubit = useBloc(() => StickerCubit(getStickers()));

    final itemCount = useBlocStateConverter<StickerCubit, List<Sticker>, int>(
      bloc: stickerCubit,
      converter: (state) => state.length,
    );
    final controller = useMemoized(ScrollController.new);
    return BlocProvider.value(
      value: stickerCubit,
      child: GridView.builder(
        controller: controller,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) => _StickerAlbumPageItem(
          index: index,
          updateUsedAt: updateUsedAt,
          rightClickDelete: rightClickDelete,
        ),
      ),
    );
  }
}

class _StickerStoreEmptyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          context.l10n.stickerStore,
          style: TextStyle(
            color: context.theme.secondaryText,
            fontSize: 18,
          ),
        ),
      );
}

class _StickerAlbumPageItem extends HookWidget {
  const _StickerAlbumPageItem({
    required this.index,
    required this.updateUsedAt,
    this.rightClickDelete = false,
  });

  final int index;
  final bool updateUsedAt;
  final bool rightClickDelete;

  @override
  Widget build(BuildContext context) {
    final sticker = useBlocStateConverter<StickerCubit, List<Sticker>, Sticker>(
      converter: (state) => state[index],
      keys: [index],
    );

    return InteractiveDecoratedBox(
      onTap: () async {
        final accountServer = context.accountServer;
        final conversationItem = context.read<ConversationCubit>().state;
        if (conversationItem == null) return;

        final albumId = await accountServer.database.stickerRelationshipDao
            .stickerSystemAlbumId(sticker.stickerId)
            .getSingleOrNull();

        await Future.wait([
          if (updateUsedAt)
            accountServer.database.stickerDao.updateUsedAt(
                sticker.albumId, sticker.stickerId, DateTime.now()),
          accountServer.sendStickerMessage(
            sticker.stickerId,
            albumId,
            conversationItem.encryptCategory,
            conversationId: conversationItem.conversationId,
            recipientId: conversationItem.user?.userId,
          ),
        ]);
      },
      onRightClick: (pointerUpEvent) async {
        if (!rightClickDelete) return;
        // todo use native context menu.
      },
      hoveringDecoration: BoxDecoration(
        color: context.dynamicColor(
          const Color.fromRGBO(229, 231, 235, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: RepaintBoundary(
          child: Builder(
            builder: (context) => StickerItem(
              assetUrl: sticker.assetUrl,
              assetType: sticker.assetType,
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerAlbumBar extends HookWidget {
  const _StickerAlbumBar({
    required this.tabLength,
    required this.tabController,
    required this.presetStickerGroups,
  });

  final int tabLength;
  final TabController tabController;
  final List<PresetStickerGroup> presetStickerGroups;

  @override
  Widget build(BuildContext context) {
    final validIndexRef = useRef<int?>(tabController.index);

    final setPreviousIndex = useCallback(() {
      final previousIndex = tabController.previousIndex;
      if (previousIndex != 0) {
        validIndexRef.value = previousIndex;
      }

      if (validIndexRef.value != 0) {
        // Sometimes tabController.index is validIndex, but TabBar.currentIndex is 0, they are not synchronized, so we need reset tabController.index to 0, then set to validIndex.
        tabController
          ..index = 0
          ..index = validIndexRef.value!;
      }
    }, []);

    useEffect(() {
      Future<void> listener() async {
        if (tabController.index != 0) return;

        HoverOverlay.forceHidden(context);
        AccountKeyValue.instance.hasNewAlbum = false;

        setPreviousIndex();
        if (!(await showStickerStorePageDialog(context))) return;
        // When the dialog is closed, the scroll status is idle most of the time, reset tabController.index to validIndex.
        setPreviousIndex();
      }

      tabController.addListener(listener);
      return () {
        tabController.removeListener(listener);
      };
    }, [tabController]);
    return Container(
      width: double.infinity,
      height: 50,
      color: context.dynamicColor(
        const Color.fromRGBO(0, 0, 0, 0.05),
        darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: context.dynamicColor(
            const Color.fromRGBO(229, 231, 235, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        labelPadding: EdgeInsets.zero,
        indicatorPadding: const EdgeInsets.all(5),
        tabs: List.generate(
          tabLength,
          (index) => _StickerAlbumBarItem(
            index: index,
            presetStickerGroups: presetStickerGroups,
          ),
        ),
      ),
    );
  }
}

class _StickerAlbumBarItem extends StatelessWidget {
  const _StickerAlbumBarItem({
    required this.index,
    required this.presetStickerGroups,
  });

  final int index;
  final List<PresetStickerGroup> presetStickerGroups;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: const Size.square(50),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: _StickerGroupIconHoverContainer(
            child: Center(
              child: Center(
                child: Builder(
                  builder: (context) {
                    final presetStickerAlbum = {
                      PresetStickerGroup.store:
                          AccountKeyValue.instance.hasNewAlbum
                              ? Resources.assetsImagesStickerStoreRedDotSvg
                              : Resources.assetsImagesStickerStoreSvg,
                      PresetStickerGroup.emoji:
                          Resources.assetsImagesEmojiStickerSvg,
                      PresetStickerGroup.recent:
                          Resources.assetsImagesRecentStickerSvg,
                      PresetStickerGroup.favorite:
                          Resources.assetsImagesPersonalStickerSvg,
                      PresetStickerGroup.gif:
                          Resources.assetsImagesGifStickerSvg,
                    };

                    if (index < presetStickerGroups.length) {
                      return SvgPicture.asset(
                        presetStickerAlbum[presetStickerGroups[index]]!,
                        colorFilter: index != 0
                            ? ColorFilter.mode(
                                context.theme.secondaryText,
                                BlendMode.srcIn,
                              )
                            : null,
                        width: 24,
                        height: 24,
                      );
                    }

                    return BlocConverter<StickerAlbumsCubit, List<StickerAlbum>,
                        String>(
                      converter: (state) =>
                          state[index - presetStickerGroups.length].iconUrl,
                      builder: (context, iconUrl) => StickerGroupIcon(
                        iconUrl: iconUrl,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
}

class _StickerGroupIconHoverContainer extends HookWidget {
  const _StickerGroupIconHoverContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isHovering = useState(false);
    return MouseRegion(
      onEnter: (event) {
        isHovering.value = true;
      },
      onExit: (event) {
        isHovering.value = false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isHovering.value
              ? context.dynamicColor(
                  const Color.fromRGBO(229, 231, 235, 1),
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                )
              : null,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: child,
      ),
    );
  }
}
