import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../account/account_key_value.dart';
import '../../bloc/bloc_converter.dart';
import '../../constants/icon_fonts.dart';
import '../../constants/resources.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../automatic_keep_alive_client_widget.dart';
import '../hover_overlay.dart';
import '../interactive_decorated_box.dart';
import '../toast.dart';
import 'add_sticker_dialog.dart';
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
    required this.tabController,
    required this.presetStickerGroups,
    super.key,
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
                                    .watchWithStream(
                                  eventStreams: [
                                    DataBaseEventBus
                                        .instance.updateStickerStream
                                  ],
                                  duration: kVerySlowThrottleDuration,
                                ),
                                updateUsedAt: false,
                              );
                            case PresetStickerGroup.favorite:
                              return _StickerAlbumPage(
                                getStickers: () => context.database.stickerDao
                                    .personalStickers()
                                    .watchWithStream(
                                  eventStreams: [
                                    DataBaseEventBus
                                        .instance.updateStickerStream
                                  ],
                                  duration: kVerySlowThrottleDuration,
                                ),
                                delete: (sticker) {
                                  final ctx = Navigator.of(context).context;
                                  showToastLoading(context: ctx);
                                  try {
                                    ctx.accountServer.client.accountApi
                                        .removeSticker([sticker.stickerId]);
                                    ctx.database.stickerDao
                                        .deletePersonalSticker(
                                            sticker.stickerId);
                                    showToastSuccessful(context: ctx);
                                  } catch (error, stacktrace) {
                                    e('removeSticker error: $error, $stacktrace');
                                    showToastFailed(error, context: ctx);
                                  }
                                },
                                canAddSticker: true,
                              );
                            case PresetStickerGroup.gif:
                              return const AutomaticKeepAliveClientWidget(
                                child: GiphyPage(),
                              );
                          }
                        }
                        return _StickerAlbumPage(
                          getStickers: () {
                            final albumId =
                                BlocProvider.of<StickerAlbumsCubit>(context)
                                    .state[index - presetStickerGroups.length]
                                    .albumId;
                            return context.database.stickerDao
                                .stickerByAlbumId(albumId)
                                .watchWithStream(
                              eventStreams: [
                                DataBaseEventBus.instance
                                    .watchUpdateStickerStream(
                                        albumIds: [albumId])
                              ],
                              duration: kVerySlowThrottleDuration,
                            );
                          },
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

class _StickerAlbumPage extends HookConsumerWidget {
  const _StickerAlbumPage({
    required this.getStickers,
    this.updateUsedAt = true,
    this.delete,
    this.canAddSticker = false,
  });

  final Stream<List<Sticker>> Function() getStickers;

  final bool updateUsedAt;
  final void Function(Sticker)? delete;
  final bool canAddSticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        itemCount: canAddSticker ? itemCount + 1 : itemCount,
        itemBuilder: (BuildContext context, int index) {
          if (canAddSticker && index == 0) {
            return const _AddStickerWidget();
          }
          return _StickerAlbumPageItem(
            index: canAddSticker ? index - 1 : index,
            updateUsedAt: updateUsedAt,
            delete: delete,
          );
        },
      ),
    );
  }
}

class _AddStickerWidget extends StatelessWidget {
  const _AddStickerWidget();

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox(
        hoveringDecoration: BoxDecoration(
          color: context.dynamicColor(
            const Color.fromRGBO(229, 231, 235, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        onTap: () async {
          try {
            final ctx = Navigator.of(context).context;
            final image =
                await ImagePicker().pickImage(source: ImageSource.gallery);
            if (image == null) {
              return;
            }
            await showAddStickerDialog(ctx, filepath: image.path);
          } catch (error, stacktrace) {
            e('pickFiles error: $error, $stacktrace');
            showToastFailed(error);
          }
        },
        child: Center(
          child: SvgPicture.asset(Resources.assetsImagesAddStickerSvg,
              width: 78,
              height: 78,
              colorFilter: ColorFilter.mode(
                context.theme.secondaryText,
                BlendMode.srcIn,
              )),
        ),
      );
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

class _StickerAlbumPageItem extends HookConsumerWidget {
  const _StickerAlbumPageItem({
    required this.index,
    required this.updateUsedAt,
    this.delete,
  });

  final int index;
  final bool updateUsedAt;
  final void Function(Sticker)? delete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sticker = useBlocStateConverter<StickerCubit, List<Sticker>, Sticker>(
      converter: (state) => state[index],
      keys: [index],
    );

    Widget widget = InteractiveDecoratedBox(
      onTap: () async {
        final accountServer = context.accountServer;
        final conversationItem = ref.read(conversationProvider);
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
    if (delete != null) {
      widget = ContextMenuWidget(
        menuProvider: (request) => Menu(children: [
          MenuAction(
            title: context.l10n.delete,
            image: MenuImage.icon(IconFonts.delete),
            callback: () => delete?.call(sticker),
          ),
        ]),
        child: widget,
      );
    }

    return widget;
  }
}

class _StickerAlbumBar extends HookConsumerWidget {
  const _StickerAlbumBar({
    required this.tabLength,
    required this.tabController,
    required this.presetStickerGroups,
  });

  final int tabLength;
  final TabController tabController;
  final List<PresetStickerGroup> presetStickerGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        tabAlignment: TabAlignment.start,
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
        size: const Size.square(48),
        child: Padding(
          padding: const EdgeInsets.all(4),
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

class _StickerGroupIconHoverContainer extends HookConsumerWidget {
  const _StickerGroupIconHoverContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
