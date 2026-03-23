import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../account/account_key_value.dart';
import '../../constants/icon_fonts.dart';
import '../../constants/resources.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/providers/home_scope_providers.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../ui/provider/database_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../utils/extension/extension.dart';
import '../automatic_keep_alive_client_widget.dart';
import '../hover_overlay.dart';
import '../interactive_decorated_box.dart';
import '../menu.dart';
import '../toast.dart';
import 'add_sticker_dialog.dart';
import 'emoji_page.dart';
import 'giphy_page.dart';
import 'sticker_item.dart';
import 'sticker_store.dart';

enum PresetStickerGroup { store, emoji, recent, favorite, gif }

enum _StickerCollectionKind { album, recent, favorite }

class _StickerCollection {
  const _StickerCollection._(this.kind, {this.albumId});

  const _StickerCollection.album(this.albumId)
    : kind = _StickerCollectionKind.album;

  const _StickerCollection.recent() : this._(_StickerCollectionKind.recent);

  const _StickerCollection.favorite() : this._(_StickerCollectionKind.favorite);

  final _StickerCollectionKind kind;
  final String? albumId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _StickerCollection &&
          other.kind == kind &&
          other.albumId == albumId;

  @override
  int get hashCode => Object.hash(kind, albumId);
}

final _stickerItemsProvider = StreamProvider.autoDispose
    .family<List<Sticker>, _StickerCollection>((ref, collection) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(const <Sticker>[]);
      }

      switch (collection.kind) {
        case _StickerCollectionKind.recent:
          return database.stickerDao.recentUsedStickers().watchWithStream(
            eventStreams: [DataBaseEventBus.instance.updateStickerStream],
            duration: kVerySlowThrottleDuration,
          );
        case _StickerCollectionKind.favorite:
          return database.stickerDao.personalStickers().watchWithStream(
            eventStreams: [DataBaseEventBus.instance.updateStickerStream],
            duration: kVerySlowThrottleDuration,
          );
        case _StickerCollectionKind.album:
          final albumId = collection.albumId;
          if (albumId == null) {
            return Stream.value(const <Sticker>[]);
          }
          return database.stickerDao
              .stickerByAlbumId(albumId)
              .watchWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateStickerStream(
                    albumIds: [albumId],
                  ),
                ],
                duration: kVerySlowThrottleDuration,
              );
      }
    });

class StickerPage extends ConsumerWidget {
  const StickerPage({
    required this.tabLength,
    required this.tabController,
    required this.presetStickerGroups,
    required this.textController,
    super.key,
  });

  final TabController tabController;
  final int tabLength;
  final List<PresetStickerGroup> presetStickerGroups;
  final TextEditingController? textController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickerAlbums =
        ref.watch(stickerAlbumsProvider).value ?? const <StickerAlbum>[];
    final accountServer = ref.read(accountServerProvider).requireValue;

    return Material(
      color: Colors.transparent,
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(11)),
      child: Container(
        width: 464,
        height: 407,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(11)),
          color: BrightnessData.dynamicColor(
            context,
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
                  children: List.generate(tabLength, (index) {
                    if (index < presetStickerGroups.length) {
                      final preset = presetStickerGroups[index];
                      switch (preset) {
                        case PresetStickerGroup.store:
                          return _StickerStoreEmptyPage();
                        case PresetStickerGroup.emoji:
                          return AutomaticKeepAliveClientWidget(
                            child: EmojiPage(textController: textController),
                          );
                        case PresetStickerGroup.recent:
                          return const _StickerAlbumPage(
                            collection: _StickerCollection.recent(),
                            updateUsedAt: false,
                          );
                        case PresetStickerGroup.favorite:
                          return _StickerAlbumPage(
                            collection: const _StickerCollection.favorite(),
                            delete: (sticker) {
                              final ctx = Navigator.of(context).context;
                              showToastLoading(context: ctx);
                              try {
                                accountServer.client.accountApi.removeSticker([
                                  sticker.stickerId,
                                ]);
                                accountServer.deletePersonalSticker(
                                  sticker.stickerId,
                                );
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
                    final album =
                        stickerAlbums[index - presetStickerGroups.length];
                    return _StickerAlbumPage(
                      collection: _StickerCollection.album(album.albumId),
                    );
                  }),
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
}

class _StickerAlbumPage extends HookConsumerWidget {
  const _StickerAlbumPage({
    required this.collection,
    this.updateUsedAt = true,
    this.delete,
    this.canAddSticker = false,
  });

  final _StickerCollection collection;
  final bool updateUsedAt;
  final void Function(Sticker)? delete;
  final bool canAddSticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickers =
        ref.watch(_stickerItemsProvider(collection)).value ?? const <Sticker>[];
    final controller = useMemoized(ScrollController.new);
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: canAddSticker ? stickers.length + 1 : stickers.length,
      itemBuilder: (context, index) {
        if (canAddSticker && index == 0) {
          return const _AddStickerWidget();
        }
        return _StickerAlbumPageItem(
          sticker: stickers[canAddSticker ? index - 1 : index],
          updateUsedAt: updateUsedAt,
          delete: delete,
        );
      },
    );
  }
}

class _AddStickerWidget extends ConsumerWidget {
  const _AddStickerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final hoverColor = ref.watch(
      dynamicColorProvider(
        (
          color: const Color.fromRGBO(229, 231, 235, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
      ),
    );
    return InteractiveDecoratedBox(
      hoveringDecoration: BoxDecoration(
        color: hoverColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      onTap: () async {
        try {
          final ctx = Navigator.of(context).context;
          final image = await ImagePicker().pickImage(
            source: ImageSource.gallery,
          );
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
        child: SvgPicture.asset(
          Resources.assetsImagesAddStickerSvg,
          width: 78,
          height: 78,
          colorFilter: ColorFilter.mode(
            theme.secondaryText,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _StickerStoreEmptyPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return Center(
      child: Text(
        l10n.stickerStore,
        style: TextStyle(
          color: theme.secondaryText,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _StickerAlbumPageItem extends HookConsumerWidget {
  const _StickerAlbumPageItem({
    required this.sticker,
    required this.updateUsedAt,
    this.delete,
  });

  final Sticker sticker;
  final bool updateUsedAt;
  final void Function(Sticker)? delete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer = ref.read(accountServerProvider).requireValue;
    final database = ref.read(databaseProvider).requireValue;
    final l10n = ref.watch(localizationProvider);
    final hoverColor = ref.watch(
      dynamicColorProvider(
        (
          color: const Color.fromRGBO(229, 231, 235, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
      ),
    );
    Widget widget = InteractiveDecoratedBox(
      onTap: () async {
        final conversationItem = ref.read(conversationProvider);
        if (conversationItem == null) return;

        final albumId = await database.stickerRelationshipDao
            .stickerSystemAlbumId(sticker.stickerId)
            .getSingleOrNull();

        await Future.wait([
          if (updateUsedAt)
            accountServer.updateStickerUsedAt(
              sticker.albumId,
              sticker.stickerId,
              DateTime.now(),
            ),
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
        color: hoverColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: RepaintBoundary(
          child: Builder(
            builder: (context) => StickerItem(
              stickerId: sticker.stickerId,
              assetUrl: sticker.assetUrl,
              assetType: sticker.assetType,
            ),
          ),
        ),
      ),
    );
    if (delete != null) {
      widget = CustomContextMenuWidget(
        menuProvider: (request) => Menu(
          children: [
            MenuAction(
              title: l10n.delete,
              image: MenuImage.icon(IconFonts.delete),
              callback: () => delete?.call(sticker),
            ),
          ],
        ),
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
    final barColor = ref.watch(
      dynamicColorProvider(
        (
          color: const Color.fromRGBO(0, 0, 0, 0.05),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
      ),
    );
    final indicatorColor = ref.watch(
      dynamicColorProvider(
        (
          color: const Color.fromRGBO(229, 231, 235, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
      ),
    );

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
      color: barColor,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: indicatorColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        labelPadding: EdgeInsets.zero,
        indicatorPadding: const EdgeInsets.all(5),
        dividerColor: Colors.transparent,
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

class _StickerAlbumBarItem extends ConsumerWidget {
  const _StickerAlbumBarItem({
    required this.index,
    required this.presetStickerGroups,
  });

  final int index;
  final List<PresetStickerGroup> presetStickerGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return SizedBox.fromSize(
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
                    PresetStickerGroup.gif: Resources.assetsImagesGifStickerSvg,
                  };

                  if (index < presetStickerGroups.length) {
                    return SvgPicture.asset(
                      presetStickerAlbum[presetStickerGroups[index]]!,
                      colorFilter: index != 0
                          ? ColorFilter.mode(
                              theme.secondaryText,
                              BlendMode.srcIn,
                            )
                          : null,
                      width: 24,
                      height: 24,
                    );
                  }

                  return _StickerAlbumIcon(
                    albumIndex: index - presetStickerGroups.length,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerAlbumIcon extends HookConsumerWidget {
  const _StickerAlbumIcon({required this.albumIndex});

  final int albumIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickerAlbums =
        ref.watch(stickerAlbumsProvider).value ?? const <StickerAlbum>[];
    final iconUrl = stickerAlbums[albumIndex].iconUrl;

    return StickerGroupIcon(iconUrl: iconUrl, size: 28);
  }
}

class _StickerGroupIconHoverContainer extends HookConsumerWidget {
  const _StickerGroupIconHoverContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovering = useState(false);
    final hoverColor = ref.watch(
      dynamicColorProvider(
        (
          color: const Color.fromRGBO(229, 231, 235, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
      ),
    );
    return MouseRegion(
      onEnter: (event) {
        isHovering.value = true;
      },
      onExit: (event) {
        isHovering.value = false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isHovering.value ? hoverColor : null,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: child,
      ),
    );
  }
}
