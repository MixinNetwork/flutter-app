import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/widgets/select_item.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SlidePage extends StatelessWidget {
  static const peopleType = [
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
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color(0xFF2C3136).withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(
            height: 48,
          ),
          Text(
            'People',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          ...peopleType.map(
            (e) => BlocConverter<SlideCategoryCubit, SlideCategoryState, bool>(
              converter: (state) =>
                  state?.type == SlideCategoryType.people &&
                  state?.name == e['title'],
              builder: (BuildContext context, bool selected) => SelectItem(
                asset: e['asset'],
                title: e['title'],
                onTap: () =>
                    BlocProvider.of<SlideCategoryCubit>(context).select(
                  SlideCategoryType.people,
                  e['title'],
                ),
                selected: selected,
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'Circle',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
            // TODO circle list 回调
            child: Builder(builder: (context) {
              const circleType = [
                {
                  'asset': Assets.assetsImagesCirclePng,
                  'title': 'Mixin',
                },
              ];
              return ListView.builder(
                itemCount: 1,
                itemBuilder: (BuildContext context, int index) {
                  return BlocConverter<SlideCategoryCubit, SlideCategoryState,
                      bool>(
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
                      );
                    },
                  );
                },
              );
            }),
          ),
          // TODO 用户信息回调
          Builder(
            builder: (context) => const SelectItem(
                asset: Assets.assetsImagesAvatarPng,
                title: 'Mixin',
              )
          ),
        ]),
      ),
    );
  }
}
