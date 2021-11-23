import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../bloc/bloc_converter.dart';
import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../generated/l10n.dart';
import '../../utils/color_utils.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/animated_visibility.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/dialog.dart';
import '../../widgets/menu.dart';
import '../../widgets/select_item.dart';
import '../../widgets/toast.dart';
import '../../widgets/user_selector/conversation_selector.dart';
import '../../widgets/window/move_window.dart';
import 'bloc/multi_auth_cubit.dart';
import 'bloc/slide_category_cubit.dart';

class SlidePage extends StatelessWidget {
  const SlidePage({
    Key? key,
    required this.showCollapse,
  }) : super(key: key);
  final bool showCollapse;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.brightnessValue == 1.0
              ? Colors.black.withOpacity(0.03)
              : Colors.white.withOpacity(0.01),
          border: Border(
            right: BorderSide(
              color: context.theme.divider,
            ),
          ),
        ),
        child: MoveWindow(
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: (defaultTargetPlatform == TargetPlatform.macOS)
                        ? 64.0
                        : 16.0),
                const _CurrentUser(),
                const SizedBox(height: 24),
                _Item(
                  asset: Resources.assetsImagesChatSvg,
                  title: context.l10n.chats,
                  type: SlideCategoryType.chats,
                ),
                const SizedBox(height: 12),
                const _Divider(),
                const SizedBox(height: 12),
                _CategoryList(
                  children: [
                    _Item(
                      asset: Resources.assetsImagesSlideContactsSvg,
                      title: context.l10n.contacts,
                      type: SlideCategoryType.contacts,
                    ),
                    _Item(
                      asset: Resources.assetsImagesGroupSvg,
                      title: context.l10n.groups,
                      type: SlideCategoryType.groups,
                    ),
                    _Item(
                      asset: Resources.assetsImagesBotSvg,
                      title: Localization.current.bots,
                      type: SlideCategoryType.bots,
                    ),
                    _Item(
                      asset: Resources.assetsImagesStrangersSvg,
                      title: context.l10n.strangers,
                      type: SlideCategoryType.strangers,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Expanded(child: _CircleList()),
                AnimatedVisibility(
                  alignment: Alignment.bottomCenter,
                  visible: showCollapse,
                  child: HookBuilder(builder: (context) {
                    final collapse = useBlocStateConverter<MultiAuthCubit,
                        MultiAuthState, bool>(
                      converter: (state) => state.collapsedSidebar,
                    );

                    return SelectItem(
                      icon: SvgPicture.asset(
                        collapse
                            ? Resources.assetsImagesExpandedSvg
                            : Resources.assetsImagesCollapseSvg,
                        width: 24,
                        height: 24,
                        color: context.theme.text,
                      ),
                      title: context.l10n.collapse,
                      onTap: () => context.multiAuthCubit
                          .setCurrentSetting(collapsedSidebar: !collapse),
                    );
                  }),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
}

class _CurrentUser extends StatelessWidget {
  const _CurrentUser({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => MoveWindowBarrier(
        child: Builder(
          builder: (context) =>
              BlocConverter<MultiAuthCubit, MultiAuthState, Account?>(
            converter: (state) => state.current?.account,
            when: (a, b) => b?.fullName != null,
            builder: (context, account) =>
                BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
              converter: (state) => state.type == SlideCategoryType.setting,
              builder: (context, selected) {
                assert(account != null);
                return SelectItem(
                  icon: AvatarWidget(
                    avatarUrl: account!.avatarUrl,
                    size: 24,
                    name: account.fullName!,
                    userId: account.userId,
                  ),
                  title: account.fullName!,
                  selected: selected,
                  onTap: () {
                    BlocProvider.of<SlideCategoryCubit>(context)
                        .select(SlideCategoryType.setting);
                    if (ModalRoute.of(context)?.canPop == true) {
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
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
      useMemoized(
          () => context.database.circleDao.allCircles().watchThrottle()),
      initialData: [],
    );
    if (circles.data?.isEmpty ?? true) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Divider(),
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
                return MoveWindowBarrier(
                  child: ContextMenuPortalEntry(
                    buildMenus: () => [
                      ContextMenu(
                          title: context.l10n.editCircleName,
                          onTap: () async {
                            final name = await showMixinDialog<String>(
                              context: context,
                              child: EditDialog(
                                editText: circle.name,
                                title: Text(context.l10n.circles),
                                hintText: context.l10n.editCircleName,
                              ),
                            );
                            if (name?.isEmpty ?? true) return;

                            await runFutureWithToast(
                              context,
                              context.accountServer
                                  .updateCircle(circle.circleId, name!),
                            );
                          }),
                      ContextMenu(
                        title: context.l10n.editCircle,
                        onTap: () async {
                          final initSelected = (await context
                                  .database.circleConversationDao
                                  .allCircleConversations(circle.circleId)
                                  .get())
                              .map((e) => ConversationSelector(
                                    conversationId: e.conversationId,
                                    userId: e.userId,
                                  ))
                              .toList();

                          final result = await showConversationSelector(
                            context: context,
                            singleSelect: false,
                            title: circle.name,
                            onlyContact: false,
                            initSelected: initSelected,
                            allowEmpty: true,
                            confirmedText: context.l10n.done,
                          );

                          if (result == null || result.isEmpty) return;

                          await runFutureWithToast(
                            context,
                            () async {
                              final add = result.where((element) =>
                                  !initSelected
                                      .map((e) => e.conversationId)
                                      .contains(element.conversationId));
                              final remove = initSelected.where((element) =>
                                  !result
                                      .map((e) => e.conversationId)
                                      .contains(element.conversationId));

                              final requests = [
                                ...add.map((e) => CircleConversationRequest(
                                      action: CircleConversationAction.add,
                                      conversationId: e.conversationId,
                                      userId: e.userId,
                                    )),
                                ...remove.map((e) => CircleConversationRequest(
                                      action: CircleConversationAction.remove,
                                      conversationId: e.conversationId,
                                      userId: e.userId,
                                    ))
                              ];
                              await context.accountServer
                                  .editCircleConversation(
                                circle.circleId,
                                requests,
                              );
                            }(),
                          );
                        },
                      ),
                      ContextMenu(
                        title: context.l10n.deleteCircle,
                        isDestructiveAction: true,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(context,
                              context.l10n.pageDeleteCircle(circle.name));
                          if (!result) return;
                          await runFutureWithToast(
                            context,
                            () async {
                              await context.accountServer
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
                      onTap: () {
                        BlocProvider.of<SlideCategoryCubit>(context).select(
                          SlideCategoryType.circle,
                          circle.circleId,
                        );
                        if (ModalRoute.of(context)?.canPop == true) {
                          Navigator.pop(context);
                        }
                      },
                      selected: selected,
                      count: circle.unseenConversationCount,
                      mutedCount: circle.unseenMutedConversationCount,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) => children[index],
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemCount: children.length,
      );
}

class _Item extends HookWidget {
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
  Widget build(BuildContext context) {
    final selected =
        useBlocStateConverter<SlideCategoryCubit, SlideCategoryState, bool>(
      converter: (state) => state.type == type,
      keys: [type],
    );
    final result = useMemoizedStream<BaseUnseenConversationCountResult>(
      () {
        final dao = context.database.conversationDao;
        switch (type) {
          case SlideCategoryType.contacts:
            return dao.contactUnseenConversationCount().watchSingleThrottle();
          case SlideCategoryType.groups:
            return dao.groupUnseenConversationCount().watchSingleThrottle();
          case SlideCategoryType.bots:
            return dao.botUnseenConversationCount().watchSingleThrottle();
          case SlideCategoryType.strangers:
            return dao.strangerUnseenConversationCount().watchSingleThrottle();
          default:
            return const Stream.empty();
        }
      },
      keys: [type],
    ).data;

    return MoveWindowBarrier(
      child: SelectItem(
        icon: SvgPicture.asset(
          asset,
          width: 24,
          height: 24,
          color: context.theme.text,
        ),
        title: title,
        onTap: () {
          BlocProvider.of<SlideCategoryCubit>(context).select(
            type,
            title,
          );
          if (ModalRoute.of(context)?.canPop == true) {
            Navigator.pop(context);
          }
        },
        selected: selected,
        count: result?.unseenConversationCount ?? 0,
        mutedCount: result?.unseenMutedConversationCount ?? 0,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        height: 1.5,
        // width: 32,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: ShapeDecoration(
          color: context.theme.listSelected,
          shape: const StadiumBorder(),
        ),
      );
}
