import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/select_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            const SizedBox(height: 64),
            const _Title(data: 'People'),
            const SizedBox(height: 12),
            _CategoryList(
              children: [
                _Item(
                  asset: Resources.assetsImagesContactsPng,
                  title: Localization.of(context).contacts,
                  type: SlideCategoryType.contacts,
                ),
                _Item(
                  asset: Resources.assetsImagesGroupPng,
                  title: Localization.of(context).group,
                  type: SlideCategoryType.groups,
                ),
                _Item(
                  asset: Resources.assetsImagesBotPng,
                  title: Localization.current.bots,
                  type: SlideCategoryType.bots,
                ),
                _Item(
                  asset: Resources.assetsImagesStrangersPng,
                  title: Localization.of(context).strangers,
                  type: SlideCategoryType.strangers,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // _Title(data: Localization.of(context).circle),
            // const SizedBox(height: 12),
            // const _CircleList(),
            const Spacer(),
            Builder(
              builder: (context) => BlocConverter<MultiAuthCubit,
                  MultiAuthState, Tuple2<String, String>>(
                converter: (state) => Tuple2(state.current?.account?.fullName,
                    state.current?.account?.avatarUrl),
                when: (a, b) => b.item1 != null && b.item2 != null,
                builder: (context, tuple) =>
                    BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
                  converter: (state) =>
                      state?.type == SlideCategoryType.setting,
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

// todo
// ignore: unused_element
class _CircleList extends StatelessWidget {
  const _CircleList({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
        // todo circle list callback
        child: Builder(
          builder: (context) {
            const circleType = [
              {
                'asset': Resources.assetsImagesCirclePng,
                'title': 'Mixin',
              },
            ];
            return ListView.separated(
              itemCount: 1,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) =>
                  BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
                converter: (state) =>
                    state?.type == SlideCategoryType.circle &&
                    state?.id == circleType[index]['title'],
                builder: (BuildContext context, bool selected) {
                  final circle = circleType[index];
                  return SelectItem(
                    icon: Image.asset(
                      circle['asset'],
                      width: 24,
                      height: 24,
                      color: BrightnessData.themeOf(context).accent,
                    ),
                    title: circle['title'],
                    onTap: () =>
                        BlocProvider.of<SlideCategoryCubit>(context).select(
                      SlideCategoryType.circle,
                      circle['title'],
                    ),
                    selected: selected,
                    count: 99,
                    onRightClick: (pointerUpEvent) async {
                      final result = await showContextMenu(
                        context: context,
                        pointerPosition: pointerUpEvent.position,
                        menus: [
                          ContextMenu(
                            title: Localization.of(context).editCircleName,
                          ),
                          ContextMenu(
                            title: Localization.of(context).editConversations,
                          ),
                          ContextMenu(
                            title: Localization.of(context).deleteCircle,
                            isDestructiveAction: true,
                            value: () {
                              showMixinDialog(
                                context: context,
                                child: AlertDialogLayout(
                                  content: Text(Localization.of(context)
                                      .pageDeleteCircle(circle['title'])),
                                  actions: [
                                    MixinButton(
                                      backgroundTransparent: true,
                                      child:
                                          Text(Localization.of(context).cancel),
                                    ),
                                    MixinButton(
                                      child:
                                          Text(Localization.of(context).delete),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                      result?.call();
                    },
                  );
                },
              ),
            );
          },
        ),
      );
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    Key key,
    @required this.children,
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
    Key key,
    @required this.type,
    @required this.title,
    @required this.asset,
  }) : super(key: key);

  final SlideCategoryType type;
  final String title;
  final String asset;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
        converter: (state) => state?.type == type,
        builder: (BuildContext context, bool selected) => SelectItem(
          icon: Image.asset(
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
    Key key,
    this.data,
  }) : super(key: key);

  final String data;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          data,
          style: TextStyle(
            color: BrightnessData.themeOf(context).secondaryText,
          ),
        ),
      );
}
