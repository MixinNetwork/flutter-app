import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../constants/resources.dart';
import '../../db/dao/sticker_album_dao.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../action_button.dart';
import '../app_bar.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../interactive_decorated_box.dart';
import 'sticker_item.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> showStickerStorePageDialog(
  BuildContext context,
) =>
    showMixinDialog(
      context: context,
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(const Size(480, 600)),
        child: Navigator(
          key: navigatorKey,
          pages: const [
            MaterialPage(child: _StickerStorePage()),
          ],
          onPopPage: (_, __) => true,
        ),
      ),
    );

Future<void> showStickerPageDialog(
  BuildContext context,
  String stickerId,
) async {
  final a = await context.database.stickerRelationshipDao
      .stickerSystemAlbum(stickerId)
      .getSingleOrNull();

  return showMixinDialog(
    context: context,
    child: ConstrainedBox(
      constraints: BoxConstraints.loose(const Size(480, 600)),
      child: HookBuilder(builder: (context) {
        final album = useMemoizedStream(() => context
                .database.stickerRelationshipDao
                .stickerSystemAlbum(stickerId)
                .watchSingleOrNullThrottle(kSlowThrottleDuration)).data ??
            a;

        useEffect(() {
          Future<void> effect() async {
            var albumId = album?.albumId;

            final accountServer = context.accountServer;
            final database = context.database;
            final client = accountServer.client;

            albumId ??= (await client.accountApi.getStickerById(stickerId))
                .data
                .albumId;

            if (albumId == null || albumId.isEmpty) return;

            final stickerAlbum =
                (await client.accountApi.getStickerAlbum(albumId)).data;
            await database.stickerAlbumDao
                .insert(stickerAlbum.asStickerAlbumsCompanion);

            await accountServer.updateStickerAlbums(albumId);
          }

          effect();
        }, [album?.albumId]);

        if (album?.albumId.isNotEmpty == true && album?.category == 'SYSTEM') {
          return _StickerAlbumPage(albumId: album!.albumId);
        }

        return _StickerPage(stickerId: stickerId);
      }),
    ),
  );
}

class _StickerStorePage extends HookWidget {
  const _StickerStorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      context.accountServer.refreshSticker(force: true);
    }, []);
    return Column(
        children: [
          MixinAppBar(
            backgroundColor: Colors.transparent,
            title: Text(context.l10n.stickerShop),
            leading: Center(
              child: ActionButton(
                name: Resources.assetsImagesSettingSvg,
                color: context.theme.icon,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ColoredBox(
                      color: context.theme.popUp,
                      child: const _StickerAlbumManagePage(),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              MixinCloseButton(
                onTap: () =>
                    Navigator.maybeOf(context, rootNavigator: true)?.pop(),
              ),
            ],
          ),
          const Expanded(child: _List()),
        ],
      );
  }
}

typedef _StickerAlbumItem = Tuple2<StickerAlbum, List<Sticker>>;

class _List extends HookWidget {
  const _List({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final albums = useMemoizedStream(() => Rx.combineLatest2<List<StickerAlbum>,
                List<Sticker>, List<_StickerAlbumItem>>(
              context.database.stickerAlbumDao
                  .systemAlbums()
                  .watchThrottle(kSlowThrottleDuration),
              context.database.stickerDao
                  .systemStickers()
                  .watchThrottle(kSlowThrottleDuration),
              (albums, stickers) => albums.map(
                (e) {
                  final _stickers = stickers
                      .where((element) => element.albumId == e.albumId)
                      .toList();
                  return _StickerAlbumItem(e, _stickers);
                },
              ).toList(),
            )).data ??
        [];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: albums.length,
      itemBuilder: (BuildContext context, int index) =>
          _Item(albums[index].item1, albums[index].item2),
    );
  }
}

class _Item extends HookWidget {
  const _Item(this.album, this.stickers, {Key? key}) : super(key: key);
  final StickerAlbum album;
  final List<Sticker> stickers;

  @override
  Widget build(BuildContext context) => SizedBox(
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
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, index) {
                          final sticker = stickers[index];

                          return InteractiveDecoratedBox(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ColoredBox(
                                  color: context.theme.popUp,
                                  child: _StickerAlbumPage(
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
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: min(4, stickers.length),
                      ),
                    ),
                    const SizedBox(width: 56),
                    AnimatedOpacity(
                      opacity: album.added == true ? 0.4 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: MixinButton(
                        onTap: () => context.database.stickerAlbumDao
                            .updateAdded(album.albumId, !(album.added == true)),
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

class _StickerAlbumPage extends StatelessWidget {
  const _StickerAlbumPage({
    Key? key,
    required this.albumId,
    this.album,
    this.stickers,
  }) : super(key: key);

  final StickerAlbum? album;
  final List<Sticker>? stickers;
  final String albumId;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          MixinAppBar(
            backgroundColor: Colors.transparent,
            title: Text(context.l10n.stickerAlbumDetail),
            leading: navigatorKey.currentState?.canPop() == true
                ? null
                : const SizedBox(),
            actions: [
              MixinCloseButton(
                onTap: () =>
                    Navigator.maybeOf(context, rootNavigator: true)?.pop(),
              ),
            ],
          ),
          Expanded(
            child: _StickerAlbumDetail(
              album: album,
              stickers: stickers,
              albumId: albumId,
            ),
          ),
        ],
      );
}

class _StickerAlbumDetail extends HookWidget {
  const _StickerAlbumDetail({
    Key? key,
    required this.albumId,
    this.album,
    this.stickers,
  }) : super(key: key);

  final StickerAlbum? album;
  final List<Sticker>? stickers;
  final String albumId;

  @override
  Widget build(BuildContext context) {
    final album = useMemoizedStream(
          () => context.database.stickerAlbumDao
              .album(albumId)
              .watchSingleThrottle(kVerySlowThrottleDuration),
          keys: [albumId],
        ).data ??
        this.album;

    final stickers = useMemoizedFuture(() async {
          if (this.stickers != null) return this.stickers;
          return context.database.stickerDao.stickerByAlbumId(albumId).get();
        }, <Sticker>[], keys: [albumId]).data ??
        [];

    if (album == null) return const SizedBox();
    return CustomScrollView(
      slivers: [
        _StickerAlbumDetailHeader(album: album, stickers: stickers),
        _StickerAlbumDetailBody(stickers: stickers),
      ],
    );
  }
}

class _StickerAlbumDetailBody extends StatelessWidget {
  const _StickerAlbumDetailBody({
    Key? key,
    required this.stickers,
  }) : super(key: key);

  final List<Sticker> stickers;

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => StickerItem(
              assetType: stickers[index].assetType,
              assetUrl: stickers[index].assetUrl,
            ),
            childCount: stickers.length,
          ),
        ),
      );
}

class _StickerAlbumDetailHeader extends StatelessWidget {
  const _StickerAlbumDetailHeader({
    Key? key,
    required this.album,
    required this.stickers,
  }) : super(key: key);

  final StickerAlbum album;
  final List stickers;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 100,
            child: Row(
              children: [
                Container(
                  width: 140,
                  height: 100,
                  alignment: Alignment.center,
                  child: StickerItem(
                    assetUrl: album.iconUrl,
                    assetType: '',
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    MixinButton(
                      backgroundColor: album.added == true
                          ? context.theme.red
                          : context.theme.accent,
                      child: Text(
                        album.added == true
                            ? context.l10n.removeStickers
                            : context.l10n.addStickers,
                      ),
                      onTap: () => context.database.stickerAlbumDao
                          .updateAdded(album.albumId, !(album.added == true)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _StickerAlbumManagePage extends HookWidget {
  const _StickerAlbumManagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();

    final albums = useMemoizedStream(() => context.database.stickerAlbumDao
        .systemAddedAlbums()
        .watchThrottle(kSlowThrottleDuration)).data;
    final list = useState(albums ?? []);
    useEffect(() {
      list.value = albums ?? [];
    }, [albums]);
    if (albums?.isEmpty ?? true) return const SizedBox();

    return Column(
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          title: Text(context.l10n.myStickerAlbums),
          actions: [
            MixinCloseButton(
              onTap: () =>
                  Navigator.maybeOf(context, rootNavigator: true)?.pop(),
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
                    recognizer:
                        ImmediateMultiDragGestureRecognizer(supportedDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    }),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  height: 72,
                  child: Row(
                    children: [
                      StickerItem(
                        assetType: '',
                        assetUrl: album.iconUrl,
                      ),
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
                        onTap: () => context.database.stickerAlbumDao
                            .updateAdded(album.albumId, false),
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

class _StickerPage extends HookWidget {
  const _StickerPage({
    Key? key,
    required this.stickerId,
  }) : super(key: key);

  final String stickerId;

  @override
  Widget build(BuildContext context) {
    final sticker = useMemoizedStream(
        () => context.database.stickerDao
            .sticker(stickerId)
            .watchSingleThrottle(kVerySlowThrottleDuration),
        keys: [stickerId]).data;

    return Column(
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          leading: const SizedBox(),
          actions: [
            MixinCloseButton(
              onTap: () =>
                  Navigator.maybeOf(context, rootNavigator: true)?.pop(),
            ),
          ],
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(56),
            color: context.theme.background,
            alignment: Alignment.center,
            child: SizedBox(
              height: 256,
              width: 256,
              child: sticker?.assetUrl.isNotEmpty == true
                  ? StickerItem(
                      assetUrl: sticker?.assetUrl ?? '',
                      assetType: sticker?.assetType ?? '',
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      ],
    );
  }
}
