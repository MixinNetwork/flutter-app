import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../constants/resources.dart';
import '../../db/dao/circle_dao.dart';
import '../../db/dao/conversation_dao.dart';
import '../../db/database_event_bus.dart';
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
import '../provider/multi_auth_provider.dart';
import '../provider/setting_provider.dart';
import '../provider/slide_category_provider.dart';

class SlidePage extends StatelessWidget {
  const SlidePage({
    super.key,
    required this.showCollapse,
  });

  final bool showCollapse;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: RepaintBoundary(
          child: DecoratedBox(
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
                      title: context.l10n.allChats,
                      type: SlideCategoryType.chats,
                    ),
                    const SizedBox(height: 12),
                    const _Divider(),
                    const SizedBox(height: 12),
                    _CategoryList(
                      children: [
                        _Item(
                          asset: Resources.assetsImagesSlideContactsSvg,
                          title: context.l10n.contactTitle,
                          type: SlideCategoryType.contacts,
                        ),
                        _Item(
                          asset: Resources.assetsImagesGroupSvg,
                          title: context.l10n.groups,
                          type: SlideCategoryType.groups,
                        ),
                        _Item(
                          asset: Resources.assetsImagesBotSvg,
                          title: Localization.current.botsTitle,
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
                      child: Consumer(builder: (context, ref, child) {
                        final collapse = ref.watch(settingProvider
                            .select((value) => value.collapsedSidebar));

                        return SelectItem(
                          icon: SvgPicture.asset(
                            collapse
                                ? Resources.assetsImagesExpandedSvg
                                : Resources.assetsImagesCollapseSvg,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              context.theme.text,
                              BlendMode.srcIn,
                            ),
                          ),
                          title: Text(context.l10n.collapse),
                          onTap: () => context.settingChangeNotifier
                              .collapsedSidebar = !collapse,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _CurrentUser extends HookConsumerWidget {
  const _CurrentUser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authAccountProvider);
    final selected = ref.watch(slideCategoryStateProvider
        .select((value) => value.type == SlideCategoryType.setting));

    return MoveWindowBarrier(
      child: SelectItem(
        icon: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AvatarWidget(
            avatarUrl: account?.avatarUrl,
            size: 24,
            name: account?.fullName,
            userId: account?.userId,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              account?.fullName ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              '${account?.identityNumber}',
              style:
                  TextStyle(color: context.theme.secondaryText, fontSize: 12),
            )
          ],
        ),
        selected: selected,
        onTap: () {
          ref
              .read(slideCategoryStateProvider.notifier)
              .select(SlideCategoryType.setting);

          if (ModalRoute.of(context)?.canPop == true) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

class _CircleList extends HookConsumerWidget {
  const _CircleList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = useMemoizedStream<List<ConversationCircleItem>>(
      () => context.database.circleDao.allCircles().watchWithStream(
        eventStreams: [
          DataBaseEventBus.instance.updateCircleStream,
          DataBaseEventBus.instance.updateCircleConversationStream,
          DataBaseEventBus.instance.updateUserIdsStream,
          DataBaseEventBus.instance.updateConversationIdStream,
        ],
        duration: kDefaultThrottleDuration,
      ),
      initialData: [],
    );
    final controller = useScrollController();
    final list = useState(circles.data ?? []);
    useEffect(() {
      list.value = circles.data ?? [];
    }, [circles.data]);
    if (circles.data?.isEmpty ?? true) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Divider(),
        const SizedBox(height: 12),
        Expanded(
          child: ReorderableList(
            controller: controller,
            onReorder: (int oldIndex, int newIndex) {
              final newList = list.value.toList();

              final _newIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
              final oldItem = newList.removeAt(oldIndex);
              newList.insert(_newIndex, oldItem);

              list.value = newList;
              context.database.circleDao.updateOrders(list.value);
            },
            itemCount: list.value.length,
            itemBuilder: (BuildContext context, int index) {
              final circle = list.value[index];
              return Consumer(
                key: Key(circle.circleId),
                builder: (BuildContext context, ref, __) {
                  final selected =
                      ref.watch(slideCategoryStateProvider.select((value) {
                    final conversationCircleItem = list.value[index];
                    return value.type == SlideCategoryType.circle &&
                        value.id == conversationCircleItem.circleId;
                  }));

                  return MoveWindowBarrier(
                    child: Listener(
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
                              }),
                        );
                      },
                      child: ContextMenuPortalEntry(
                        buildMenus: () => [
                          ContextMenu(
                              icon: Resources.assetsImagesContextMenuEditSvg,
                              title: context.l10n.editCircleName,
                              onTap: () async {
                                final name = await showMixinDialog<String>(
                                  context: context,
                                  child: EditDialog(
                                    editText: circle.name,
                                    title: Text(context.l10n.circles),
                                    hintText: context.l10n.editCircleName,
                                    positiveAction: context.l10n.edit,
                                    maxLength: 64,
                                  ),
                                );
                                if (name?.isEmpty ?? true) return;

                                await runFutureWithToast(
                                  context.accountServer
                                      .updateCircle(circle.circleId, name!),
                                );
                              }),
                          ContextMenu(
                            icon:
                                Resources.assetsImagesContextMenuEditCircleSvg,
                            title: context.l10n.editConversations,
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
                                    ...remove
                                        .map((e) => CircleConversationRequest(
                                              action: CircleConversationAction
                                                  .remove,
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
                            icon: Resources.assetsImagesContextMenuDeleteSvg,
                            title: context.l10n.deleteCircle,
                            isDestructiveAction: true,
                            onTap: () async {
                              final result = await showConfirmMixinDialog(
                                  context,
                                  context.l10n.deleteTheCircle(circle.name));
                              if (result == null) return;
                              await runFutureWithToast(
                                () async {
                                  await context.accountServer
                                      .deleteCircle(circle.circleId);
                                  ref
                                      .read(slideCategoryStateProvider.notifier)
                                      .select(SlideCategoryType.chats);
                                }(),
                              );
                            },
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SelectItem(
                            icon: SvgPicture.asset(
                              Resources.assetsImagesCircleSvg,
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                getCircleColorById(circle.circleId),
                                BlendMode.srcIn,
                              ),
                            ),
                            title: Text(circle.name),
                            onTap: () {
                              ref
                                  .read(slideCategoryStateProvider.notifier)
                                  .select(SlideCategoryType.circle,
                                      circle.circleId);

                              if (ModalRoute.of(context)?.canPop == true) {
                                Navigator.pop(context);
                              }
                            },
                            selected: selected,
                            count: circle.unseenConversationCount,
                            mutedCount: circle.unseenMutedConversationCount,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryList extends HookConsumerWidget {
  const _CategoryList({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useScrollController();
    return ListView.separated(
      controller: controller,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) => children[index],
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 8),
      itemCount: children.length,
    );
  }
}

class _Item extends HookConsumerWidget {
  const _Item({
    required this.type,
    required this.title,
    required this.asset,
  });

  final SlideCategoryType type;
  final String title;
  final String asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
        slideCategoryStateProvider.select((value) => value.type == type));

    final result = useMemoizedStream<BaseUnseenConversationCountResult>(
      () {
        final dao = context.database.conversationDao;
        switch (type) {
          case SlideCategoryType.contacts:
          case SlideCategoryType.groups:
          case SlideCategoryType.bots:
          case SlideCategoryType.strangers:
            return dao
                .unseenConversationCountByCategory(type)
                .watchSingleWithStream(
              eventStreams: [
                DataBaseEventBus.instance.updateConversationIdStream
              ],
              duration: kDefaultThrottleDuration,
            );
          case SlideCategoryType.chats:
          case SlideCategoryType.circle:
          case SlideCategoryType.setting:
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
          colorFilter: ColorFilter.mode(context.theme.text, BlendMode.srcIn),
        ),
        title: Text(title),
        onTap: () {
          ref.read(slideCategoryStateProvider.notifier).select(type, title);

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
  const _Divider();

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
