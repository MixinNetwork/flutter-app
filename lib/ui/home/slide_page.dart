import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/utils/color_utils.dart';
import 'package:flutter_app/widgets/Toast.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/menu.dart';
import 'package:flutter_app/widgets/select_item.dart';
import 'package:flutter_app/widgets/user_selector/conversation_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_app/generated/l10n.dart';

class SlidePage extends StatelessWidget {
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
                  MultiAuthState, Tuple2<String, String>>(
                converter: (state) => Tuple2(state.current!.account.fullName!,
                    state.current!.account.avatarUrl!),
                when: (a, b) => b?.item1 != null && b?.item2 != null,
                builder: (context, tuple) =>
                    BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
                  converter: (state) => state.type == SlideCategoryType.setting,
                  builder: (context, selected) => SelectItem(
                    icon: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: tuple.item2,
                        width: 30,
                        height: 30,
                      ),
                    ),
                    title: tuple.item1,
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
                    buildMenus: () => [
                      ContextMenu(
                          title: Localization.of(context).editCircleName,
                          onTap: () async {
                            final name = await showMixinDialog<String>(
                              context: context,
                              child: EditCircleNameDialog(name: circle.name),
                            );
                            if(name?.isEmpty ?? true) return;

                            showToastLoading(context);

                            try {
                              await context.read<AccountServer>().updateCircle(circle.circleId, name!);
                            } catch (e) {
                              return showToastFailed(context);
                            }
                            showToastSuccessful(context);
                          }),
                      ContextMenu(
                        title: Localization.of(context).editConversations,
                        onTap: () async {
                          final initSelectIds = (await context
                                  .read<AccountServer>()
                                  .database
                                  .circleConversationDao
                                  .allCircleConversations(circle.circleId)
                                  .get())
                              .map((e) => e.userId ?? e.conversationId)
                              .toList();
                          final result = await showConversationSelector(
                            context: context,
                            singleSelect: false,
                            title: circle.name,
                            onlyContact: false,
                            initSelectIds: initSelectIds,
                          );

                          // todo result update circle
                        },
                      ),
                      ContextMenu(
                        title: Localization.of(context).deleteCircle,
                        isDestructiveAction: true,
                        onTap: () {
                          showMixinDialog(
                            context: context,
                            child: AlertDialogLayout(
                              content: Text(Localization.of(context)
                                  .pageDeleteCircle(circle.name)),
                              actions: [
                                MixinButton(
                                  backgroundTransparent: true,
                                  child: Text(Localization.of(context).cancel),
                                  onTap: () => Navigator.pop(context),
                                ),
                                MixinButton(
                                  child: Text(Localization.of(context).delete),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context
                                        .read<AccountServer>()
                                        .database
                                        .circlesDao
                                        .deleteCircle(circle.circleId);
                                    BlocProvider.of<SlideCategoryCubit>(context)
                                        .select(
                                      SlideCategoryType.contacts,
                                      Localization.of(context).contacts,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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

class EditCircleNameDialog extends HookWidget {
  const EditCircleNameDialog({
    Key? key,
    this.name = '',
  }) : super(key: key);

  final String name;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController.call(text: name);
    return AlertDialogLayout(
      title: Text(Localization.of(context).circles),
      content: DialogTextField(
          textEditingController: textEditingController,
          hintText: Localization.of(context).conversationName),
      actions: [
        MixinButton(
            backgroundTransparent: true,
            child: Text(Localization.of(context).cancel),
            onTap: () => Navigator.pop(context)),
        MixinButton(
          child: Text(Localization.of(context).create),
          onTap: () => Navigator.pop(context, textEditingController.text),
        ),
      ],
    );
  }
}
