import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

import '../../bloc/bloc_converter.dart';
import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../cache_image.dart';
import '../interactive_decorated_box.dart';
import 'bloc/cubit/sticker_albums_cubit.dart';
import 'bloc/cubit/sticker_cubit.dart';

class StickerPage extends StatelessWidget {
  const StickerPage({
    required this.tabLength,
    Key? key,
    this.tabController,
  }) : super(key: key);

  final TabController? tabController;
  final int tabLength;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(11)),
        child: Container(
          width: 464,
          height: 407,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: context.dynamicColor(
              const Color.fromRGBO(255, 255, 255, 1),
              darkColor: const Color.fromRGBO(62, 65, 72, 1),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: List.generate(
                      tabLength,
                      (index) => _StickerAlbumPage(index: index),
                    ),
                  ),
                ),
                _StickerAlbumBar(
                  tabLength: tabLength,
                  tabController: tabController,
                ),
              ],
            ),
          ),
        ),
      );
}

class _StickerAlbumPage extends HookWidget {
  const _StickerAlbumPage({
    Key? key,
    required this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    final stickerDao = context.database.stickerDao;
    if (index == 1) {
      // todo can add or delete
    }
    final updateUsedAt = index != 0;
    final rightClickDelete = index == 1;
    final stickerCubit = useBloc(() {
      Stream<List<Sticker>> stream;
      switch (index) {
        case 0:
          stream = stickerDao.recentUsedStickers().watchThrottle();
          break;
        case 1:
          stream = stickerDao.personalStickers().watchThrottle();
          break;
        default:
          stream = stickerDao
              .stickerByAlbumId(BlocProvider.of<StickerAlbumsCubit>(context)
                  .state[index - 2]
                  .albumId)
              .watchThrottle();
      }
      return StickerCubit(stream);
    }, keys: [index]);

    final itemCount = useBlocStateConverter<StickerCubit, List<Sticker>, int>(
      bloc: stickerCubit,
      converter: (state) => state.length,
    );
    return BlocProvider.value(
      value: stickerCubit,
      child: GridView.builder(
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

class _StickerAlbumPageItem extends HookWidget {
  const _StickerAlbumPageItem({
    Key? key,
    required this.index,
    required this.updateUsedAt,
    this.rightClickDelete = false,
  }) : super(key: key);

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

        await Future.wait([
          if (updateUsedAt)
            accountServer.database.stickerDao
                .updateUsedAt(sticker.stickerId, DateTime.now()),
          accountServer.sendStickerMessage(
            sticker.stickerId,
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
      child: RepaintBoundary(
        child: Builder(builder: (context) {
          if (sticker.assetType == 'json') {
            return Lottie.network(
              sticker.assetUrl,
              fit: BoxFit.cover,
            );
          }
          return CacheImage(sticker.assetUrl);
        }),
      ),
    );
  }
}

class _StickerAlbumBar extends StatelessWidget {
  const _StickerAlbumBar({
    Key? key,
    required this.tabLength,
    this.tabController,
  }) : super(key: key);

  final int tabLength;
  final TabController? tabController;

  @override
  Widget build(BuildContext context) => Container(
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
            borderRadius: BorderRadius.circular(8),
          ),
          labelPadding: EdgeInsets.zero,
          indicatorPadding: const EdgeInsets.all(5),
          tabs: List.generate(
            tabLength,
            (index) => _StickerAlbumBarItem(index: index),
          ),
        ),
      );
}

class _StickerAlbumBarItem extends StatelessWidget {
  const _StickerAlbumBarItem({
    Key? key,
    required this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: const Size.square(50),
        child: Center(
          child: Center(
            child: Builder(
              builder: (context) {
                if (index < 2) {
                  return SvgPicture.asset(
                    const {
                      0: Resources.assetsImagesRecentStickerSvg,
                      1: Resources.assetsImagesPersonalStickerSvg,
                      // todo
                      // 2: Resources.assetsImagesGifStickerSvg
                    }[index]!,
                    color: context.theme.secondaryText,
                    width: 24,
                    height: 24,
                  );
                }

                return BlocConverter<StickerAlbumsCubit, List<StickerAlbum>,
                    String>(
                  converter: (state) => state[index - 2].iconUrl,
                  builder: (context, iconUrl) => CacheImage(
                    iconUrl,
                    width: 28,
                    height: 28,
                  ),
                );
              },
            ),
          ),
        ),
      );
}
