import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/select_item.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SlidePage extends StatelessWidget {
  static const categoryList = [
    {
      'asset': Assets.assetsImagesContactsPng,
      'title': 'Contacts',
    },
    {
      'asset': Assets.assetsImagesGroupPng,
      'title': 'Group',
    },
    {
      'asset': Assets.assetsImagesBotPng,
      'title': 'Bots',
    },
    {
      'asset': Assets.assetsImagesStrangersPng,
      'title': 'Strangers',
    },
  ];

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
            const _CategoryList(categoryList: categoryList),
            const SizedBox(height: 16),
            const _Title(data: 'Circle'),
            const SizedBox(height: 12),
            const _CircleList(),
            // TODO user profile callback
            Builder(
              builder: (context) => const SelectItem(
                asset: Assets.assetsImagesAvatarPng,
                title: 'Mixin',
              ),
            ),
            const SizedBox(height: 4),
          ]),
        ),
      );
}

class _CircleList extends StatelessWidget {
  const _CircleList({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
        // TODO circle list callback
        child: Builder(builder: (context) {
          const circleType = [
            {
              'asset': Assets.assetsImagesCirclePng,
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
                  state?.type == SlideCategoryType.people &&
                  state?.name == circleType[index]['title'],
              builder: (BuildContext context, bool selected) {
                final circle = circleType[index];
                return SelectItem(
                  asset: circle['asset'],
                  title: circle['title'],
                  onTap: () =>
                      BlocProvider.of<SlideCategoryCubit>(context).select(
                    SlideCategoryType.people,
                    circle['title'],
                  ),
                  selected: selected,
                  iconColor: const Color.fromRGBO(65, 145, 255, 1),
                  count: 99,
                );
              },
            ),
          );
        }),
      );
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    Key key,
    @required this.categoryList,
  }) : super(key: key);

  final List<Map<String, String>> categoryList;

  @override
  Widget build(BuildContext context) => ListView.separated(
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          final item = categoryList[index];
          return BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
            converter: (state) =>
                state?.type == SlideCategoryType.people &&
                state?.name == item['title'],
            builder: (BuildContext context, bool selected) => SelectItem(
              asset: item['asset'],
              title: item['title'],
              onTap: () => BlocProvider.of<SlideCategoryCubit>(context).select(
                SlideCategoryType.people,
                item['title'],
              ),
              selected: selected,
              iconColor: BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(51, 51, 51, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemCount: categoryList.length,
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
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(51, 51, 51, 0.3),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.3),
            ),
          ),
        ),
      );
}
