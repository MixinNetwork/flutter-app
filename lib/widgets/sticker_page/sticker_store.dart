import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants/resources.dart';
import '../../db/dao/sticker_album_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../action_button.dart';
import '../app_bar.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../interactive_decorated_box.dart';
import 'sticker_album_page.dart';
import 'sticker_item.dart';

final navigatorKey = GlobalKey<NavigatorState>();
const _kStickerStoreName = 'StickerStore';

bool _checkStickerStorePageDialogMounted(BuildContext context) {
  if (navigatorKey.currentContext != null) return true;

  var topIsStickerStore = false;
  // check top route is sticker store
  Navigator.maybeOf(context, rootNavigator: true)?.popUntil((route) {
    topIsStickerStore = route.settings.name == _kStickerStoreName;
    return true;
  });
  return topIsStickerStore;
}

Future<bool> showStickerStorePageDialog(BuildContext context) async {
  if (_checkStickerStorePageDialogMounted(context)) return false;

  await showMixinDialog(
    context: context,
    routeSettings: const RouteSettings(name: _kStickerStoreName),
    child: ConstrainedBox(
      constraints: BoxConstraints.loose(const Size(480, 600)),
      child: Navigator(
        key: navigatorKey,
        onDidRemovePage: (page) {},
        pages: const [MaterialPage(child: _StickerStorePage())],
      ),
    ),
  );
  return true;
}

Future<void> showStickerPageDialog(
  BuildContext context,
  String stickerId,
) async {
  final a =
      await context.database.stickerRelationshipDao
          .stickerSystemAlbum(stickerId)
          .getSingleOrNull();

  return showMixinDialog(
    context: context,
    child: Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          // minHeight: 600,
        ),
        child: HookBuilder(
          builder: (context) {
            final album =
                useMemoizedStream(
                  () => context.database.stickerRelationshipDao
                      .stickerSystemAlbum(stickerId)
                      .watchSingleOrNullWithStream(
                        eventStreams: [
                          DataBaseEventBus.instance.watchUpdateStickerStream(
                            stickerIds: [stickerId],
                          ),
                        ],
                        duration: kSlowThrottleDuration,
                      ),
                ).data ??
                a;

            useEffect(() {
              Future<void> effect() async {
                var albumId = album?.albumId;

                final accountServer = context.accountServer;
                final database = context.database;
                final client = accountServer.client;

                albumId ??=
                    (await client.accountApi.getStickerById(
                      stickerId,
                    )).data.albumId;

                if (albumId == null || albumId.isEmpty) return;

                final stickerAlbum =
                    (await client.accountApi.getStickerAlbum(albumId)).data;
                await database.stickerAlbumDao.insert(
                  stickerAlbum.asStickerAlbumsCompanion,
                );

                await accountServer.updateStickerAlbums(albumId);
              }

              effect();
            }, [album?.albumId]);

            final albumId =
                album?.albumId.isNotEmpty == true && album?.category == 'SYSTEM'
                    ? album!.albumId
                    : null;

            return _StickerPage(stickerId: stickerId, albumId: albumId);
          },
        ),
      ),
    ),
  );
}

class _StickerStorePage extends HookConsumerWidget {
  const _StickerStorePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      context.accountServer.refreshSticker(force: true);
    }, []);
    return Column(
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          title: Text(context.l10n.stickerStore),
          leading: Center(
            child: ActionButton(
              name: Resources.assetsImagesSettingSvg,
              color: context.theme.icon,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ColoredBox(
                            color: context.theme.popUp,
                            child: const _StickerAlbumManagePage(),
                          ),
                    ),
                  ),
            ),
          ),
          actions: [
            MixinCloseButton(
              onTap:
                  () => Navigator.maybeOf(context, rootNavigator: true)?.pop(),
            ),
          ],
        ),
        const Expanded(child: _List()),
      ],
    );
  }
}

class _List extends HookConsumerWidget {
  const _List();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums =
        useMemoizedStream(
          () => Rx.combineLatest2<
            List<StickerAlbum>,
            List<Sticker>,
            List<(StickerAlbum, List<Sticker>)>
          >(
            context.database.stickerAlbumDao.systemAlbums().watchWithStream(
              eventStreams: [DataBaseEventBus.instance.updateStickerStream],
              duration: kSlowThrottleDuration,
            ),
            context.database.stickerDao.systemStickers().watchWithStream(
              eventStreams: [DataBaseEventBus.instance.updateStickerStream],
              duration: kSlowThrottleDuration,
            ),
            (albums, stickers) =>
                albums
                    .map(
                      (e) => (
                        e,
                        stickers
                            .where((element) => element.albumId == e.albumId)
                            .toList(),
                      ),
                    )
                    .toList(),
          ),
        ).data ??
        [];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: albums.length,
      itemBuilder: (BuildContext context, int index) {
        final (album, stickers) = albums[index];
        return _Item(album, stickers);
      },
    );
  }
}

class _Item extends HookConsumerWidget {
  const _Item(this.album, this.stickers);

  final StickerAlbum album;
  final List<Sticker> stickers;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height: 104,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            album.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.theme.text,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (final sticker in stickers.take(4))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InteractiveDecoratedBox(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ColoredBox(
                                    color: context.theme.popUp,
                                    child: StickerAlbumPage(
                                      album: album,
                                      stickers: stickers,
                                      albumId: album.albumId,
                                    ),
                                  ),
                            ),
                          ),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: StickerItem(
                          assetUrl: sticker.assetUrl,
                          assetType: sticker.assetType,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: album.added == true ? 0.4 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: MixinButton(
                    onTap:
                        () => context.database.stickerAlbumDao.updateAdded(
                          album.albumId,
                          !(album.added == true),
                        ),
                    child: Text(
                      album.added == true
                          ? context.l10n.added
                          : context.l10n.add,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StickerAlbumManagePage extends HookConsumerWidget {
  const _StickerAlbumManagePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useScrollController();

    final albums =
        useMemoizedStream(
          () => context.database.stickerAlbumDao
              .systemAddedAlbums()
              .watchWithStream(
                eventStreams: [DataBaseEventBus.instance.updateStickerStream],
                duration: kSlowThrottleDuration,
              ),
        ).data;
    final list = useState(albums ?? []);
    useEffect(() {
      list.value = albums ?? [];
    }, [albums]);
    if (albums?.isEmpty ?? true) return const SizedBox();

    return Column(
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          title: Text(context.l10n.myStickers),
          actions: [
            MixinCloseButton(
              onTap:
                  () => Navigator.maybeOf(context, rootNavigator: true)?.pop(),
            ),
          ],
        ),
        Expanded(
          child: ReorderableList(
            controller: controller,
            itemCount: list.value.length,
            onReorder: (int oldIndex, int newIndex) {
              final newList = list.value.toList();

              final _newIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
              final oldItem = newList.removeAt(oldIndex);
              newList.insert(_newIndex, oldItem);

              list.value = newList;
              context.database.stickerAlbumDao.updateOrders(list.value);
            },
            itemBuilder: (context, index) {
              final album = list.value[index];
              return Listener(
                key: ValueKey(album.albumId),
                onPointerDown: (event) {
                  if (event.buttons != kPrimaryButton) {
                    // Only accept primary button event, ignore right click event.
                    return;
                  }
                  ReorderableList.maybeOf(context)?.startItemDragReorder(
                    index: index,
                    event: event,
                    recognizer: ImmediateMultiDragGestureRecognizer(
                      supportedDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  height: 72,
                  child: Row(
                    children: [
                      StickerGroupIcon(iconUrl: album.iconUrl, size: 72),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          album.name,
                          style: TextStyle(
                            color: context.theme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ActionButton(
                        name: Resources.assetsImagesDeleteSvg,
                        color: context.theme.secondaryText,
                        onTap:
                            () => context.database.stickerAlbumDao.updateAdded(
                              album.albumId,
                              false,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StickerPage extends HookConsumerWidget {
  const _StickerPage({required this.stickerId, this.albumId});

  final String stickerId;
  final String? albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sticker = useState<Sticker?>(null);
    useEffect(() {
      Future<void> effect() async {
        final s =
            await context.database.stickerDao
                .sticker(stickerId)
                .getSingleOrNull();
        sticker.value = s;
      }

      effect();
      return;
    }, []);

    final album =
        useMemoizedStream(() {
          if (albumId == null) return Stream.value(null);
          return context.database.stickerAlbumDao
              .album(albumId!)
              .watchSingleWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateStickerStream(
                    albumIds: [albumId!],
                  ),
                ],
                duration: kDefaultThrottleDuration,
              );
        }, keys: [albumId]).data;

    final stickers =
        useMemoizedStream(() {
          if (album == null) return Stream.value(<Sticker>[]);
          return context.database.stickerDao
              .stickerByAlbumId(album.albumId)
              .watchWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateStickerStream(
                    albumIds: [album.albumId],
                  ),
                ],
                duration: kDefaultThrottleDuration,
              );
        }, keys: [album?.albumId]).data ??
        [];

    return DefaultTabController(
      length: stickers.length,
      child: HookBuilder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          useEffect(() {
            void listener() {
              sticker.value = stickers[tabController.index];
            }

            tabController.addListener(listener);

            return () {
              tabController.removeListener(listener);
            };
          }, [tabController]);

          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MixinAppBar(
                  backgroundColor: Colors.transparent,
                  leading: const SizedBox(),
                  actions: [
                    MixinCloseButton(
                      onTap:
                          () =>
                              Navigator.maybeOf(
                                context,
                                rootNavigator: true,
                              )?.pop(),
                    ),
                  ],
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(56).copyWith(top: 0),
                    color: context.theme.background,
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 256,
                      width: 256,
                      child:
                          sticker.value?.assetUrl.isNotEmpty == true
                              ? StickerItem(
                                assetUrl: sticker.value?.assetUrl ?? '',
                                assetType: sticker.value?.assetType ?? '',
                              )
                              : const SizedBox(),
                    ),
                  ),
                ),
                if (album != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            album.name,
                            style: TextStyle(
                              color: context.theme.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        MixinButton(
                          backgroundColor:
                              album.added == true
                                  ? context.theme.red
                                  : context.theme.accent,
                          onTap:
                              () =>
                                  context.database.stickerAlbumDao.updateAdded(
                                    album.albumId,
                                    !(album.added == true),
                                  ),
                          child: Text(
                            album.added == true
                                ? context.l10n.removeStickers
                                : context.l10n.addStickers,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (album != null && stickers.isNotEmpty)
                  TabBar(
                    isScrollable: true,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicator: BoxDecoration(
                      color: context.dynamicColor(
                        const Color.fromRGBO(229, 231, 235, 1),
                        darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    labelPadding: EdgeInsets.zero,
                    indicatorPadding: const EdgeInsets.all(6),
                    tabs:
                        stickers
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.all(16),
                                child: StickerItem(
                                  assetUrl: e.assetUrl,
                                  assetType: e.assetType,
                                  width: 64,
                                  height: 64,
                                ),
                              ),
                            )
                            .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
