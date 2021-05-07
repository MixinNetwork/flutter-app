import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:tuple/tuple.dart';

import '../../account/account_server.dart';
import '../../bloc/bloc_converter.dart';
import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../generated/l10n.dart';
import '../../utils/color_utils.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/dialog.dart';
import '../../widgets/menu.dart';
import '../../widgets/select_item.dart';
import '../../widgets/toast.dart';
import '../../widgets/user_selector/conversation_selector.dart';
import 'bloc/multi_auth_cubit.dart';
import 'bloc/slide_category_cubit.dart';

class SlidePage extends StatelessWidget {
  const SlidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 48),
            _Item(
              asset: Resources.assetsImagesChatSvg,
              title: Localization.of(context).chats,
              type: SlideCategoryType.chats,
            ),
            const SizedBox(height: 12),
            _Title(data: Localization.of(context).people),
            const SizedBox(height: 12),
            _CategoryList(
              children: [
                _Item(
                  asset: Resources.assetsImagesSlideContactsSvg,
                  title: Localization.of(context).contacts,
                  type: SlideCategoryType.contacts,
                ),
                _Item(
                  asset: Resources.assetsImagesGroupSvg,
                  title: Localization.of(context).group,
                  type: SlideCategoryType.groups,
                ),
                _Item(
                  asset: Resources.assetsImagesBotSvg,
                  title: Localization.current.bots,
                  type: SlideCategoryType.bots,
                ),
                _Item(
                  asset: Resources.assetsImagesStrangersSvg,
                  title: Localization.of(context).strangers,
                  type: SlideCategoryType.strangers,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _CircleList(),
            const Spacer(),
            Builder(
              builder: (context) => BlocConverter<MultiAuthCubit,
                  MultiAuthState, Tuple2<String?, String?>>(
                converter: (state) => Tuple2(state.current?.account.fullName,
                    state.current?.account.avatarUrl),
                when: (a, b) => b?.item1 != null && b?.item2 != null,
                builder: (context, tuple) =>
                    BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
                  converter: (state) => state.type == SlideCategoryType.setting,
                  builder: (context, selected) => SelectItem(
                    icon: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: tuple.item2!,
                        width: 30,
                        height: 30,
                      ),
                    ),
                    title: tuple.item1!,
                    selected: selected,
                    onTap: () => BlocProvider.of<SlideCategoryCubit>(context)
                        .select(SlideCategoryType.setting),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ]),
        ),
      );
}

class _CircleList extends HookWidget {
  const _CircleList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final circles = useStream<List<ConversationCircleItem>>(
      useMemoized(() => context
          .read<AccountServer>()
          .database
          .circlesDao
          .allCircles()
          .watch()),
      initialData: [],
    );
    if (circles.data?.isEmpty ?? true) return const SizedBox();
    return Expanded(
      child: Column(
        children: [
          _Title(data: Localization.of(context).circles),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: circles.data!.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) =>
                  BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
                converter: (state) {
                  final conversationCircleItem = circles.data![index];
                  return state.type == SlideCategoryType.circle &&
                      state.id == conversationCircleItem.circleId;
                },
                builder: (BuildContext context, bool selected) {
                  final circle = circles.data![index];
                  return ContextMenuPortalEntry(
                    buildMenus: () => [
                      ContextMenu(
                          title: Localization.of(context).editCircleName,
                          onTap: () async {
                            final name = await showMixinDialog<String>(
                              context: context,
                              child: EditDialog(
                                editText: circle.name,
                                title: Text(Localization.of(context).circles),
                                hintText:
                                    Localization.of(context).editCircleName,
                              ),
                            );
                            if (name?.isEmpty ?? true) return;

                            await runFutureWithToast(
                              context,
                              context
                                  .read<AccountServer>()
                                  .updateCircle(circle.circleId, name!),
                            );
                          }),
                      ContextMenu(
                        title: Localization.of(context).editConversations,
                        onTap: () async {
                          final initSelected = (await context
                                  .read<AccountServer>()
                                  .database
                                  .circleConversationDao
                                  .allCircleConversations(circle.circleId)
                                  .get())
                              .map((e) => ConversationSelector(
                                    conversationId: e.conversationId,
                                    userId: e.userId,
                                    isBot: false,
                                    isGroup: false,
                                  ))
                              .toList();

                          final result = await showConversationSelector(
                            context: context,
                            singleSelect: false,
                            title: circle.name,
                            onlyContact: false,
                            initSelected: initSelected,
                          );

                          final add = result.where((element) => !initSelected
                              .map((e) => e.conversationId)
                              .contains(element.conversationId));
                          final remove = initSelected.where((element) => !result
                              .map((e) => e.conversationId)
                              .contains(element.conversationId));

                          final requests = [
                            ...add.map((e) => CircleConversationRequest(
                                  action: CircleConversationAction.ADD,
                                  conversationId: e.conversationId,
                                  userId: e.userId,
                                )),
                            ...remove.map((e) => CircleConversationRequest(
                                  action: CircleConversationAction.REMOVE,
                                  conversationId: e.conversationId,
                                  userId: e.userId,
                                ))
                          ];
                          await runFutureWithToast(
                            context,
                            context
                                .read<AccountServer>()
                                .editCircleConversation(
                                  circle.circleId,
                                  requests,
                                ),
                          );
                        },
                      ),
                      ContextMenu(
                        title: Localization.of(context).deleteCircle,
                        isDestructiveAction: true,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                              context,
                              Localization.of(context)
                                  .pageDeleteCircle(circle.name));
                          if (!result) return;
                          await runFutureWithToast(
                            context,
                            () async {
                              await context
                                  .read<AccountServer>()
                                  .deleteCircle(circle.circleId);
                              context
                                  .read<SlideCategoryCubit>()
                                  .select(SlideCategoryType.chats);
                            }(),
                          );
                        },
                      ),
                    ],
                    child: SelectItem(
                      icon: SvgPicture.asset(
                        Resources.assetsImagesCircleSvg,
                        width: 24,
                        height: 24,
                        color: getCircleColorById(circle.circleId),
                      ),
                      title: circle.name,
                      onTap: () =>
                          BlocProvider.of<SlideCategoryCubit>(context).select(
                        SlideCategoryType.circle,
                        circle.circleId,
                      ),
                      selected: selected,
                      count: circle.unseenMessageCount ?? 0,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView.separated(
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) => children[index],
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemCount: children.length,
      );
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.type,
    required this.title,
    required this.asset,
  }) : super(key: key);

  final SlideCategoryType type;
  final String title;
  final String asset;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
        converter: (state) => state.type == type,
        builder: (BuildContext context, bool selected) => SelectItem(
          icon: SvgPicture.asset(
            asset,
            width: 24,
            height: 24,
            color: BrightnessData.themeOf(context).text,
          ),
          title: title,
          onTap: () => BlocProvider.of<SlideCategoryCubit>(context).select(
            type,
            title,
          ),
          selected: selected,
        ),
      );
}

class _Title extends StatelessWidget {
  const _Title({
    Key? key,
    required this.data,
  }) : super(key: key);

  final String data;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                data,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).secondaryText,
                ),
              ),
            ),
          ],
        ),
      );
}
